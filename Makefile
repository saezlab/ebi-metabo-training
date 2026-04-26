.PHONY: help setup setup-r setup-python notebooks check-r check-py clean-results

help:
	@echo "Targets:"
	@echo "  setup          R + Python environment setup"
	@echo "  setup-r        R only (PPM binaries via pak)"
	@echo "  setup-python   Python only (uv sync)"
	@echo "  notebooks      Rebuild .ipynb files from scripts/ via jupytext"
	@echo "  check-r        Smoke-test the R notebook end-to-end"
	@echo "  check-py       Smoke-test the Python notebook end-to-end"
	@echo "  clean-results  Wipe results/"

setup: setup-r setup-python

setup-r:
	Rscript env/install.R

setup-python:
	cd env && uv sync

notebooks:
	cd env && uv run jupytext --to notebook --output ../notebooks/metabo_R.ipynb       ../scripts/R/_notebook.R
	cd env && uv run jupytext --to notebook --output ../notebooks/metabo_python.ipynb ../scripts/python/_notebook.py

check-r:
	cd env && uv run jupyter nbconvert --to notebook --execute --inplace ../notebooks/metabo_R.ipynb

check-py:
	cd env && uv run jupyter nbconvert --to notebook --execute --inplace ../notebooks/metabo_python.ipynb

clean-results:
	rm -rf results/*
