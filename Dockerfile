import os
import tempfile
import traceback
from flask import Flask, request, send_file, jsonify
from flask_cors import CORS
from assinar_pdf import assinar_pdf

app = Flask(__name__, static_folder="static", static_url_path="")
CORS(app)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
SIG_PATH  = os.path.join(BASE_DIR, "assinatura_paula.png")


@app.route("/")
def index():
    return app.send_static_file("index.html")


@app.route("/assinar", methods=["POST"])
def assinar():
    if "pdf" not in request.files:
        return jsonify({"erro": "Nenhum PDF enviado."}), 400

    pdf_file = request.files["pdf"]
    if not pdf_file.filename.lower().endswith(".pdf"):
        return jsonify({"erro": "O arquivo precisa ser um PDF."}), 400

    try:
        with tempfile.TemporaryDirectory() as tmpdir:
            input_path  = os.path.join(tmpdir, "entrada.pdf")
            output_path = os.path.join(tmpdir, "assinado.pdf")

            pdf_file.save(input_path)
            assinar_pdf(input_path, SIG_PATH, output_path)

            # Nome de saída = nome original + _assinado
            original_stem = os.path.splitext(pdf_file.filename)[0]
            download_name = f"{original_stem}_assinado.pdf"

            return send_file(
                output_path,
                mimetype="application/pdf",
                as_attachment=True,
                download_name=download_name
            )

    except ValueError as e:
        return jsonify({"erro": str(e)}), 422
    except Exception:
        traceback.print_exc()
        return jsonify({"erro": "Erro interno ao processar o PDF."}), 500


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port)
