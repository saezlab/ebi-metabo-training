"""Build a single Jupyter notebook from numbered jupytext source files.

Each input file is read as a jupytext notebook; a synthesized markdown
section banner is prepended to every file's cells (renumbering the
author's leading H1 to match the order in the bundled notebook). A
secondary divider can be inserted before a supplementary block (e.g.
77_/88_ holding cells in the R source set).

Usage::

    python build_notebook.py \
        --kernel python3 \
        --output ../notebooks/metabo_python.ipynb \
        --main 01_client_intro.py 02_id_and_orthology.py \
        --supplementary 77_misc.py
"""

from __future__ import annotations

import re
import sys
import argparse
from pathlib import Path

import jupytext
import nbformat


_LEADING_NUM_RX = re.compile(r'^\s*\d+[_\-]')
_H1_LINE_RX = re.compile(r'^#\s+\d+\.\s*(.*)$', re.MULTILINE)


def _title_from_filename(path: Path) -> str:

    stem = path.stem
    base = _LEADING_NUM_RX.sub('', stem).replace('_', ' ').strip()

    return base[:1].upper() + base[1:] if base else stem


def _renumber_or_prepend_banner(
    nb: nbformat.NotebookNode,
    section_no: int,
    fallback_title: str,
) -> None:
    """Mutate ``nb`` so its first H1 heading reflects ``section_no``.

    If the first markdown cell already has an ``# # N. Title`` line,
    rewrite the number while preserving the author's title text.
    Otherwise, prepend a synthesized banner cell.
    """

    banner = f'# {section_no}. {fallback_title}'

    for cell in nb.cells:

        if cell.cell_type != 'markdown':
            continue

        new_src, n = _H1_LINE_RX.subn(
            lambda m: f'# {section_no}. {m.group(1)}',
            cell.source,
            count=1,
        )

        if n:
            cell.source = new_src
            return

        break

    nb.cells.insert(
        0,
        nbformat.v4.new_markdown_cell(banner),
    )


def _make_divider(title: str) -> nbformat.NotebookNode:

    return nbformat.v4.new_markdown_cell(f'# {title}')


def build(
    main: list[Path],
    supplementary: list[Path],
    output: Path,
    kernel: str,
    supp_divider_title: str = 'Optional supplementary sections',
) -> None:

    out_nb = nbformat.v4.new_notebook()
    out_nb.cells = []
    section_no = 0

    for src in main:

        section_no += 1
        nb = jupytext.read(src)
        _renumber_or_prepend_banner(
            nb,
            section_no,
            _title_from_filename(src),
        )
        out_nb.cells.extend(nb.cells)

    if supplementary:

        out_nb.cells.append(_make_divider(supp_divider_title))

        for src in supplementary:

            section_no += 1
            nb = jupytext.read(src)
            _renumber_or_prepend_banner(
                nb,
                section_no,
                _title_from_filename(src),
            )
            out_nb.cells.extend(nb.cells)

    # Pin the kernel so the notebook is auto-selected on open.
    out_nb.metadata['kernelspec'] = {
        'name': kernel,
        'display_name': kernel,
        'language': 'R' if kernel.startswith('ir') else 'python',
    }

    output.parent.mkdir(parents=True, exist_ok=True)
    nbformat.write(out_nb, str(output))


def _parse() -> argparse.Namespace:

    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--kernel', required=True)
    p.add_argument('--output', required=True, type=Path)
    p.add_argument('--main', nargs='+', required=True, type=Path)
    p.add_argument('--supplementary', nargs='*', default=[], type=Path)
    p.add_argument(
        '--supp-divider',
        default='Optional supplementary sections',
    )

    return p.parse_args()


if __name__ == '__main__':

    args = _parse()

    try:
        build(
            main=args.main,
            supplementary=args.supplementary,
            output=args.output,
            kernel=args.kernel,
            supp_divider_title=args.supp_divider,
        )

    except FileNotFoundError as e:
        sys.exit(f'build_notebook: {e}')

    print(f'Wrote {args.output}')
