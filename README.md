**Đây là dự án nhầm mục đích nghiên cứu RAG, LLM. phục vụ việc hỏi đáp tài liệu nội bộ.
Triển khai ở nền tản web và mobile.**
<img width="1848" height="873" alt="image" src="https://github.com/user-attachments/assets/ccc179bb-1ecd-415d-ada6-326b7b99ff2d" />
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/e50fe99e-e0a3-49ba-9eac-1c7a6228928d" />
****Triển khai:**
Chunking (Chia nhỏ văn bản)
Mục đích
Không nhét cả file lớn vào model. Giúp tìm kiếm chính xác hơn. Tăng khả năng match với query
Phương Pháp chunking: Overlap. chunk_size=1000, overlap=200

**Embedding Model intfloat/multilingual-e5-large:**
Dùng tốt cho xử lý tiếng việt
ChromaDB sử dụng theo mô hình trên để convert các text về vector và lưu trữ
 LLM (Gemini / Gemma):
1 Hiểu context hội thoại, viết lại câu hỏi rõ ràng
2 trả lời dựa vào: CONTEXT (từ ChromaDB đã qua xử lý), HISTORY, QUESTION
<img width="879" height="456" alt="image" src="https://github.com/user-attachments/assets/a9202ee8-55e0-4fc9-9f9a-040791b172b6" />
<img width="887" height="398" alt="image" src="https://github.com/user-attachments/assets/c9d22460-c4a3-48b5-ac54-d6baeaf153aa" />
<img width="966" height="624" alt="image" src="https://github.com/user-attachments/assets/8998a765-cf1a-444c-9b41-102be23225dd" />
<img width="741" height="498" alt="image" src="https://github.com/user-attachments/assets/6d9022be-7514-4019-a0e4-70d0fe692abd" />




