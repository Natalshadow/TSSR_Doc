import pathlib, re, yaml

SRC = pathlib.Path("docs/Glossaire")      # adjust to your glossary folder
OUT = SRC / "Index.md"                    # generated page, skipped on reading

link = re.compile(r"\[\[(?:[^\]|]*\|)?([^\]]+)\]\]")   # [[A|B]] -> B, [[A]] -> A

rows = []
for f in sorted(SRC.glob("*.md")):
    if f == OUT:
        continue
    text = f.read_text(encoding="utf-8")
    meta, body = {}, text
    if text.startswith("---"):
        _, fm, body = text.split("---", 2)
        meta = yaml.safe_load(fm) or {}
    aliases = ", ".join(meta.get("aliases") or [])
    first = next((l.strip() for l in body.splitlines() if l.strip()), "")
    first = link.sub(r"\1", first).replace("|", "\\|")
    rows.append(f"| {f.stem} | {aliases} | {first} |")

OUT.write_text(
    "# Glossaire\n\n| Terme | Alias | Définition |\n|---|---|---|\n"
    + "\n".join(rows) + "\n",
    encoding="utf-8",
)