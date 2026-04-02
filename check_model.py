import fitz
import re  # Thêm thư viện regex

def extract_footnotes(pdf_path):
    doc = fitz.open(pdf_path)
    results = []
    all_lines = []

    for page_num, page in enumerate(doc):
        text_dict = page.get_text("dict")
        for block in text_dict["blocks"]:
            if "lines" not in block: continue
            for line in block["lines"]:
                spans = line["spans"]
                text = " ".join([s["text"] for s in spans]).strip()
                if not text: continue
                font = spans[0]["size"]
                y = line["bbox"][1]

                if font <= 12.0:
                    all_lines.append({"text": text, "font": font, "page": page_num, "y": y})

    all_lines.sort(key=lambda x: (x["page"], x["y"]))

    cleaned_lines = []
    in_garbage_block = False

    for line in all_lines:
        text = line["text"]
        font = line["font"]

        # 1. Loại bỏ số trang (Regex kiểm tra nếu text chỉ là con số)
        # ^\d+$ nghĩa là từ đầu đến cuối chỉ có chữ số
        if re.match(r"^\d+$", text):
            continue

        # 2. Loại bỏ khu vực Nơi nhận (như cũ)
        if "Nơi nhận:" in text and font >= 10.5:
            in_garbage_block = True
            continue
        
        if in_garbage_block:
            if font >= 10.5 and (text.startswith("-") or "Lưu:" in text):
                continue
            else:
                in_garbage_block = False
                
        if font >= 10.5 and (
            text.startswith("- Văn phòng") or 
            text.startswith("- Bộ trưởng") or 
            text.startswith("- Thứ trưởng") or 
            text.startswith("- Cổng TTĐT") or 
            text.startswith("- Các") or
            "- Lưu:" in text
        ):
            continue

        cleaned_lines.append(line)

    # Ghép chuỗi
    current_note = ""
    for line in cleaned_lines:
        text = line["text"]
        font = line["font"]

        if font <= 10.0:
            if current_note:
                results.append(f"**Chú thích:**\n\n{current_note.strip()}\n")
            current_note = text
        else:
            # Kiểm tra thêm một lần nữa ở đây để tránh nối số trang vào text nếu regex sót
            if not re.match(r"^\d+$", text):
                current_note += " " + text

    if current_note:
        results.append(f"**Chú thích:**\n\n{current_note.strip()}\n")

    return results

# Chạy thử
footnotes = extract_footnotes(r"D:\AI_chatbot\File_data\94_ĐHSPKT_ĐH_Đà_Nẵng_DSK_ThongTin_TuyenSinh_ĐHCQ_2025_15062025_VF6.pdf")
for f in footnotes:
    print(f)
    print("-" * 50)