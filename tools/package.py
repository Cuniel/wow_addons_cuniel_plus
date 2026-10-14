from pathlib import Path
import zipfile
root = Path(__file__).resolve().parents[1]
addon = root / "Cuniel_plus"
version = next(line.split(":", 1)[1].strip() for line in (addon / "Cuniel_plus.toc").read_text(encoding="utf-8").splitlines() if line.startswith("## Version:"))
dest = root / "dist"
dest.mkdir(exist_ok=True)
output = dest / ("Cuniel_plus-" + version + ".zip")
with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as z:
    for file in sorted(addon.rglob("*")):
        if file.is_file() and ".git" not in file.parts:
            z.write(file, "Cuniel_plus/" + file.relative_to(addon).as_posix())
print(output)
