"""Bounded PHATE feasibility run on the unchanged retinal PC cache.

Run tools/prepare-retinal-phate-input.R first. Outputs stay in artifacts/.
The pilot uses the displayed cells; the full run fits every original cell
before extracting those same displayed cells. No expression preprocessing,
additional PCA, or coordinate standardization is performed here.
"""

import argparse
import hashlib
import importlib.metadata
import json
import os
from pathlib import Path
import resource
import sys
import threading
import time

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--population", choices=["pilot", "full"], required=True)
parser.add_argument("--directory", type=Path, default=Path("artifacts/retinal-phate"))
parser.add_argument("--seconds", type=int, default=1800)
parser.add_argument("--max-rss-gib", type=float, default=12)
args = parser.parse_args()

# Bound BLAS/OpenMP pools before importing numerical libraries.
for name in ("OMP_NUM_THREADS", "OPENBLAS_NUM_THREADS", "MKL_NUM_THREADS",
             "VECLIB_MAXIMUM_THREADS", "NUMEXPR_NUM_THREADS"):
    os.environ[name] = "4"

import numpy as np
import phate
import psutil
from scipy.sparse.csgraph import connected_components
from threadpoolctl import threadpool_limits

out = args.directory / args.population
out.mkdir(parents=True, exist_ok=True)
result_path = out / "result.json"
if result_path.exists():
    raise FileExistsError(f"Refusing to overwrite previous run: {result_path}")
manifest = json.loads((args.directory / "input.json").read_text())
binary = args.directory / "pc20-float64.bin"
assert hashlib.md5(binary.read_bytes()).hexdigest() == manifest["binary.md5"]
X = np.fromfile(binary, dtype="<f8").reshape(
    (manifest["rows"], manifest["columns"]), order="F")
index = np.genfromtxt(args.directory / "display-index.csv", delimiter=",",
                     skip_header=1, usecols=0, dtype=int)
assert X.shape == (120804, 20) and np.isfinite(X).all()
assert index.shape == (12000,) and len(np.unique(index)) == 12000
if args.population == "pilot":
    X = X[index]
params = dict(n_components=3, n_pca=None, knn=5, decay=40,
              knn_dist="euclidean", knn_max=None, n_landmark=2000,
              random_landmarking=False, t="auto", gamma=1,
              mds="metric", mds_solver="sgd", n_jobs=4,
              random_state=20190619, verbose=1)
result = dict(status="running", population=args.population, shape=list(X.shape),
              parameters=params, input=manifest,
              versions={p: importlib.metadata.version(p) for p in
                        ("phate", "graphtools", "numpy", "scipy", "scikit-learn")})
result_path.write_text(json.dumps(result, indent=2))
start = time.monotonic()
done = threading.Event()
process = psutil.Process()

def guard():
    while not done.wait(1):
        elapsed = time.monotonic() - start
        rss = process.memory_info().rss
        if elapsed > args.seconds or rss > args.max_rss_gib * 2**30:
            result.update(status="resource_limit", elapsed_seconds=elapsed,
                          rss_gib=rss / 2**30)
            result_path.write_text(json.dumps(result, indent=2))
            print("Stopped this feasibility run at its resource limit.", flush=True)
            os._exit(124)

threading.Thread(target=guard, daemon=True).start()
try:
    print(f"Fitting {X.shape[0]:,} rows; 2,000 spectral landmarks; 4 threads", flush=True)
    with threadpool_limits(limits=4):
        model = phate.PHATE(**params)
        Y = model.fit_transform(X)
    elapsed = time.monotonic() - start
    assert Y.shape == (len(X), 3) and np.isfinite(Y).all()
    assert np.linalg.matrix_rank(Y - Y.mean(axis=0)) == 3
    np.save(out / "coordinates.npy", Y)
    shown = Y if args.population == "pilot" else Y[index]
    np.savetxt(out / "display-coordinates.csv", shown, delimiter=",",
               header="x,y,z", comments="", fmt="%.17g")
    peak = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
    peak_bytes = peak if sys.platform == "darwin" else peak * 1024
    result.update(status="complete", elapsed_seconds=elapsed,
                  peak_rss_gib=peak_bytes / 2**30, optimal_t=int(model.optimal_t),
                  kernel_nnz=int(model.graph.kernel.nnz),
                  graph_components=int(connected_components(model.graph.kernel,
                                                            directed=False)[0]),
                  landmark_shape=list(model.graph.landmark_op.shape),
                  output_shape=list(Y.shape),
                  display_shape=list(shown.shape),
                  coordinate_sha256=hashlib.sha256(
                      (out / "coordinates.npy").read_bytes()).hexdigest())
except Exception as error:
    result.update(status="failed", error=repr(error),
                  elapsed_seconds=time.monotonic() - start)
    raise
finally:
    done.set()
    result_path.write_text(json.dumps(result, indent=2))
    print(json.dumps(result, indent=2), flush=True)
