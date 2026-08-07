"""把 Noto Serif SC 可变字体固定到一个字重并裁剪成常用汉字子集，
用作 App 标题字体，控制体积。仅一次性构建工具，可保留供以后重跑。"""
import sys
from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

SRC = "assets/fonts/NotoSerifSC.ttf"
OUT = "assets/fonts/NotoSerifSC-Display.ttf"
WEIGHT = 600  # 优雅的 semibold，用于标题


def gb2312_chars() -> str:
    chars = []
    for hi in range(0xA1, 0xF8):
        for lo in range(0xA1, 0xFF):
            try:
                ch = bytes([hi, lo]).decode("gb2312")
                chars.append(ch)
            except UnicodeDecodeError:
                pass
    return "".join(chars)


def main() -> None:
    text = gb2312_chars()
    # ASCII + 常用中英标点
    text += "".join(chr(c) for c in range(0x20, 0x7F))
    text += "　、。〃々〆〇《》「」『』【】〔〕・ˉˇ¨‘’“”…—～‰′″℃￥·×÷"
    text += "①②③④⑤⑥⑦⑧⑨⑩→←↑↓★☆■□●○◆◇▲△"

    print(f"chars: {len(set(text))}")

    font = TTFont(SRC)
    # 固定字重轴
    inst = instancer.instantiateVariableFont(font, {"wght": WEIGHT})

    options = subset.Options()
    options.glyph_names = False
    options.recalc_bounds = True
    options.recalc_timestamp = False
    options.drop_tables = ["DSIG"]
    options.name_IDs = ["*"]
    options.name_legacy = True
    options.notdef_outline = True
    options.layout_features = ["*"]

    subsetter = subset.Subsetter(options=options)
    subsetter.populate(text=text)
    subsetter.subset(inst)
    inst.save(OUT)
    print(f"saved {OUT}")


if __name__ == "__main__":
    sys.exit(main())
