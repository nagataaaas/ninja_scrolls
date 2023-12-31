import json
import os
from pathlib import Path


def classify(text: str) -> str:
    result = text[0].upper()
    text = text[1:]
    while text:
        if text[0] == "_":
            result += text[1].upper()
            text = text[2:]
        else:
            result += text[0].lower()
            text = text[1:]
    return result

def load_data() -> dict[str, dict[str, dict[str, int]]]:
    result = {}
    file_dir = Path(__file__).parent
    models_dir = file_dir / Path("models")

    for file in os.listdir(models_dir):
        with open(models_dir / Path(file), "r", encoding="utf-8") as f:
            data = json.load(f)
        name = file.split(".")[0]
        for v in data.values():
            for vv in v.keys():
                if not isinstance(v[vv], int):
                    raise TypeError(f"Expected int, got {type(v[vv])}")
        result[name] = data
    return result

def build_model_class(models: dict[str, dict[str, dict[str, int]]]):
    file_dir = Path(__file__).parent
    output_dir = file_dir / Path("output")
    output_dir.mkdir(parents=True, exist_ok=True)

    model_template = (file_dir / Path("templates") / Path("model.dart.template")).read_text(encoding="utf-8")

    for lang, model in models.items():
        total_score = sum(map(lambda x: sum(x.values()), model.values()))
        result = model_template.replace("<%lang%>", classify(lang))
        result = result.replace("<%total_score%>", str(total_score))
        result = result.replace("<%model%>", str(model))

        with open(output_dir / Path(f"{lang}_model.dart"), "w", encoding="utf-8") as f:
            f.write(result)
        

if __name__ == "__main__":
    data = load_data()
    build_model_class(data)