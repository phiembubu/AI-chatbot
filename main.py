import chromadb
import os
from chromadb.utils import embedding_functions
from sentence_transformers import CrossEncoder
import google.generativeai as genai
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
import json
from datetime import datetime
from fastapi import FastAPI, UploadFile,File, HTTPException
import shutil



app = FastAPI(title="SchoolHub RAG API")
DATA_DIR = "File_data"
# cho phép frontend gọi API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class Query(BaseModel):
    question: str

# 4. ENDPOINT CHAT
@app.post("/ask")
async def ask(query: Query):
    # Đảm bảo rag_pipeline đã được định nghĩa
    answer = rag_pipeline(query.question)
    return {"answer": answer}


class FeedbackRequest(BaseModel):
    question: str
    answer: str
    rating: str
    username: Optional[str] = "Anonymous"

# 3. ENDPOINT UPLOAD 
@app.post("/admin/upload")
async def upload_document(file: UploadFile = File(...)):
    if not file.filename.endswith('.txt'):
        raise HTTPException(status_code=400, detail="Chỉ chấp nhận file .txt")

    file_path = os.path.join(DATA_DIR, file.filename)

    try:
        # Lưu file
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        # Nạp ngay vào ChromaDB (Hot-update)
        ingest_file(file_path)
        
        return {"status": "success", "message": f"Đã nạp tri thức từ {file.filename}"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/admin/files")
async def list_files():
    if not os.path.exists(DATA_DIR):
        return {"files": []}
    files = [f for f in os.listdir(DATA_DIR) if f.endswith('.txt')]
    return {"files": files}

@app.delete("/admin/delete/{filename}")
async def delete_file(filename: str):
    file_path = os.path.join(DATA_DIR, filename)
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="File không tồn tại")
    try:
        os.remove(file_path)
        # Bổ sung xóa file tương ứng trong ChromaDB nếu đang chạy
        try:
            collection.delete(where={"source": filename})
        except Exception as db_err:
            print(f"Lỗi khi xóa trong DB: {db_err}")
            
        return {"status": "success", "message": f"Đã xóa {filename}"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/feedback")
async def submit_feedback(feedback: FeedbackRequest):
    FEEDBACK_FILE = "feedback.json"
    data = []
    if os.path.exists(FEEDBACK_FILE):
        try:
            with open(FEEDBACK_FILE, "r", encoding="utf-8") as f:
                data = json.load(f)
        except json.JSONDecodeError:
            pass
            
    entry = feedback.dict()
    entry["timestamp"] = datetime.now().isoformat()
    data.append(entry)
    
    with open(FEEDBACK_FILE, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=4, ensure_ascii=False)
        
    return {"status": "success"}


# ================== KHỞI TẠO GEMINI ==================

genai.configure(api_key="AIzaSyACEqmjPt9zRen13EoIMqbL6sqkycJl7WI")

# Khởi tạo model
model_gemini = genai.GenerativeModel('models/gemma-3-27b-it') ##LMM
reranker = CrossEncoder('cross-encoder/mmarco-mMiniLMv2-L12-H384-v1') ## Lọc lại contexts trả về từ query
## Tạo embedding để chỉ  định DB sử dụng
embedding_fn = embedding_functions.SentenceTransformerEmbeddingFunction( 
    model_name="intfloat/multilingual-e5-large")

# ================== KHỞI TẠO CHROMADB ==================
chroma_client = chromadb.Client()
collection = chroma_client.get_or_create_collection(
    name="documents", embedding_function=embedding_fn)## (tên, model embedding)

# Hàm rerank dùng CrossEncoder để đánh giá lại độ liên quan của các chunks với câu hỏi
def rerank(query, chunks, top_k=3):
    pairs = [(query, chunk) for chunk in chunks]
    scores = reranker.predict(pairs)

    scored = list(zip(scores, chunks))
    scored.sort(reverse=True)

    return [c[1] for c in scored[:top_k]]


## chia nhỏ văn bản
def chunk_text(text, chunk_size=1000, overlap=200):
    chunks = []
    start = 0
    while start < len(text):
        end = start + chunk_size
        chunks.append(text[start:end])
        start += (chunk_size - overlap)
    return chunks


def load_data(folder_path):
    if collection.count() > 0:
        return
    id_counter = 0
    for file in os.listdir(folder_path):
        if not file.endswith(".txt"):
            continue
        file_path = os.path.join(folder_path, file)
        with open(file_path, 'r', encoding='utf-8') as f:
            text = " ".join(f.read().split())
        chunks = chunk_text(text)
        for i, chunk in enumerate(chunks):
            collection.add(documents=[chunk], ids=[str(id_counter)], metadatas=[
                           {"source": file, "chunk_id": i}])
            id_counter += 1
    print(f"Đã nạp xong {id_counter} chunks.")

def ingest_file(file_path):
    if not file_path.endswith(".txt"):
        return
    file_name = os.path.basename(file_path)
    with open(file_path, 'r', encoding='utf-8') as f:
        text = " ".join(f.read().split())
    chunks = chunk_text(text)
    
    for i, chunk in enumerate(chunks):
        chunk_id_str = f"{file_name}_{i}"
        collection.add(
            documents=[chunk], 
            ids=[chunk_id_str], 
            metadatas=[{"source": file_name, "chunk_id": i}]
        )
    print(f"Đã nạp {len(chunks)} chunks từ {file_name}.")

#============search===========
def search(query, top_k):  
    results = collection.query(query_texts=[query], n_results=top_k)
    return results["documents"][0]

def format_history(history):
    return "\n".join([
        f"Người dùng: {m['content']}" if m["role"]=="user"
        else f"Trợ lý: {m['content']}"
        for m in history
    ])
## ====================== BUILD PROMPT ======================
def build_prompt(contexts, question, history):
    context_text = "\n---\n".join(contexts)
    history_text = format_history(history)

    return f"""
Bạn là trợ lý AI.

QUY TẮC:
- CHỈ dùng thông tin trong TÀI LIỆU để trả lời
- Không được suy diễn ngoài TÀI LIỆU
- Được phép suy luận dựa trên TÀI LIỆU, nhưng đưa ra dẫn chứng rõ ràng từ TÀI LIỆU
- HISTORY chỉ để hiểu câu hỏi
- Được phép hỏi lại nếu câu hỏi không rõ ràng, nhưng phải dựa trên LỊCH SỬ để làm rõ ý định của người dùng.
- Nếu CÂU HỎI là "", hãy hỏi lại người dùng để có câu hỏi rõ ràng hơn.
LỊCH SỬ:
{history_text}

TÀI LIỆU:
{context_text}

CÂU HỎI:
{question}

TRẢ LỜI:
"""

## Hàm keyword_filter để lọc lại contexts dựa trên từ khóa trong câu hỏi, giúp tăng độ chính xác của thông tin được sử dụng trong prompt
# def keyword_filter(chunks, query):
#     keywords = query.lower().split()
#     return [c for c in chunks if any(k in c.lower() for k in keywords)]

##============Rewrite============== vietlai
def rewrite(user_input, history_user):
    #  dùng history_text đã nối chuỗi
    history_text = "\n".join([
        f"{m['role'].upper()}: {m['content']}" for m in history_user
    ])

    prompt = f"""
Nhiệm vụ: Viết lại 'CÂU HỎI MỚI' thành một câu hoàn chỉnh, rõ ràng dựa trên 'LỊCH SỬ'.

LUẬT CỨNG:
1. KHÔNG giải thích, KHÔNG chào hỏi.
2. CHỈ TRẢ VỀ DUY NHẤT CÂU HỎI ĐÃ VIẾT LẠI.
3. Nếu không cần viết lại, hãy trả về nguyên văn câu hỏi mới.
4. GIỮ NGUYÊN cấu trúc hỏi và từ để hỏi (ví dụ: "là gì", "thế nào", "bao nhiêu", "ở đâu").
5. Nếu không phải câu hỏi, hãy giữ nguyên văn không cần Viết lại 'CÂU HỎI MỚI'.


---
LỊCH SỬ:
{history_text}

CÂU HỎI MỚI: {user_input}

VIẾT LẠI TẠI ĐÂY:""" 

    try:
        response = model_gemini.generate_content(
            prompt,
            generation_config=genai.types.GenerationConfig(
                temperature=0, # Giảm sáng tạo để tránh lỗi ký tự lạ
                max_output_tokens=250 # Tăng lên để tránh bị cắt cụt
            )
        )
        
        # Xử lý để lấy kết quả sạch nhất
        rewritten_query = response.text.strip()
        
        # Bảo hiểm: Nếu AI trả về quá ngắn, gây thiếu thông tin, lấy luôn user_input gốc
        if len(rewritten_query) < 2:
            return user_input
            
        return rewritten_query
    except Exception as e:
        print(f"Lỗi Rewrite: {e}")
        return user_input


def rag_pipeline(user_input):  
    if os.path.exists(DATA_DIR):
        load_data(DATA_DIR)

    chat_history = []
    chat_user = []
    ## viết lại câu hỏi rõ hơn
    search_query = rewrite(user_input, chat_user) 
    #print(f"\nCâu hỏi đã được viết lại: {search_query}")
    
    

    # ================== 2. RAG ==================
    ## tìm kiếm thông tin liên quan trong DB
    raw_contexts = search(search_query, top_k=20)
    ## có thể căn  nhắc giữ hoặc bỏ raw_contexts để xem ảnh hưởng đến kết quả trả về
    # raw_contexts = keyword_filter(raw_contexts, search_query) ## filter lại context theo từ khóa
    #  rerank
    filtered_contexts = rerank(search_query, raw_contexts, top_k=10) ## lọc lại contexts

    final_prompt = build_prompt(filtered_contexts, user_input, chat_history) 
    
    # ================== 3. GENERATE ==================
    try:
        response = model_gemini.generate_content(
            final_prompt,
            generation_config=genai.types.GenerationConfig(
                temperature=0.1,
                max_output_tokens=300
            )
        )

        reply = response.text 

        #print("\nBot:", reply)
        
        # lưu lịch sử
        chat_history.append({"role": "user", "content": user_input})
        chat_history.append({"role": "model", "content": reply})
        chat_user.append({"role": "user", "content": user_input})
        if len(chat_history) > 4:
            chat_history = chat_history[-4:]

        if len(chat_user) > 4:
            chat_user = chat_user[-4:]

    except Exception as e:
        print(f"Lỗi: {e}")
    return reply