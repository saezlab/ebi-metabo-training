.PHONY: help setup setup-r setup-python register-r-kernel notebooks check-r check-py clean-results

# uv is commonly installed under ~/.local/bin (curl installer) which
# isn't on $PATH for non-login shells. Prepend it so the Makefile is
# resilient to that.
export PATH := $(HOME)/.local/bin:$(PATH)

help:
	@echo "Targets:"
	@echo "  setup              R + Python environment setup + R-kernel registration"
	@echo "  setup-r            R only (PPM binaries via pak)"
	@echo "  setup-python       Python only (uv sync)"
	@echo "  register-r-kernel  Register the R kernel with the venv's Jupyter"
	@echo "                     (must run AFTER setup-python so jupyter is on PATH)"
	@echo "  notebooks          Rebuild .ipynb files from scripts/ via jupytext"
	@echo "  check-r            Smoke-test the R notebook end-to-end"
	@echo "  check-py           Smoke-test the Python notebook end-to-end"
	@echo "  clean-results      Wipe results/"

setup: setup-r setup-python register-r-kernel

setup-r:
	Rscript env/install.R

setup-python:
	cd env && uv sync
	@cd env && SP=$$(.venv/bin/python -c 'import sysconfig; print(sysconfig.get_paths()["purelib"])') && \
		echo "$$PWD/../scripts/python" > "$$SP/metabo2026-scripts.pth" && \
		echo "Wrote $$SP/metabo2026-scripts.pth -> $$PWD/../scripts/python"

# Run IRkernel::installspec from inside the uv venv so `jupyter` is on
# PATH and the kernel spec lands where the venv's jupyter looks for it.
register-r-kernel:
	cd env && PATH="$$PWD/.venv/bin:$$PATH" Rscript -e 'IRkernel::installspec(name = "ir-metabo2026", displayname = "R (metabo2026)", user = TRUE)'

notebooks:
	cd env && uv run python build_notebook.py \
		--kernel ir-metabo2026 \
		--output ../notebooks/metabo_R.ipynb \
		--main ../scripts/R/01_prior_knowledge.R \
		       ../scripts/R/02_id_workflow.R \
		       ../scripts/R/03_id_to_pk.R \
		       ../scripts/R/04_enrichment.R \
		--supplementary ../scripts/R/77_processing_data_cells.R \
		                ../scripts/R/88_differential_analysis_cells.R
	cd env && uv run python build_notebook.py \
		--kernel python3 \
		--output ../notebooks/metabo_python.ipynb \
		--main ../scripts/python/01_client_intro.py \
		       ../scripts/python/02_id_and_orthology.py \
		       ../scripts/python/03_cosmos_pkn_client.py \
		       ../scripts/python/04_metabo_gem_raw.py \
		       ../scripts/python/05_metabo_brenda.py

check-r:
	cd env && uv run jupyter nbconvert --to notebook --execute --inplace ../notebooks/metabo_R.ipynb

check-py:
	cd env && uv run jupyter nbconvert --to notebook --execute --inplace ../notebooks/metabo_python.ipynb

clean-results:
	rm -rf results/*
