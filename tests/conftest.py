"""Configuração global do pytest: garante que raiz, ia/ e BD/ estejam no sys.path."""

import sys
from pathlib import Path

RAIZ_REPOSITORIO = Path(__file__).resolve().parent.parent
for _dir in (RAIZ_REPOSITORIO, RAIZ_REPOSITORIO / "ia", RAIZ_REPOSITORIO / "BD"):
    if str(_dir) not in sys.path:
        sys.path.insert(0, str(_dir))
