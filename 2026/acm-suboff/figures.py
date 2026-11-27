"""Render the report's quantitative figures from archived tables (PYTHONPATH=DNDSR root)."""
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd
from matplotlib.ticker import FixedLocator, FuncFormatter, MultipleLocator

from scripts.dndsr_pub_plot import PublicationStyle, apply_publication_style, save_figure, series_encoding

ROOT = Path(__file__).resolve().parent
STYLE = PublicationStyle(dpi=300, target_markers=16)
apply_publication_style(STYLE)


def save(fig, stem):
    for fmt in ("png", "pdf"):
        save_figure(fig, ROOT / "figures" / f"{stem}.{fmt}", style=STYLE, bbox_inches=None)
    plt.close(fig)


def meridian():
    samples = pd.read_csv(ROOT / "evidence/meridian.csv")
    labels = {"P1": "P1, mesh 02", "P2": "P2/Q3, mesh 02", "P1 flux": "P1 wall flux, mesh 01"}
    fig, axes = plt.subplots(2, 1, figsize=(6, 6.1), sharex=True, layout="constrained")
    for axis, quantity, scale in zip(axes, ["Cp", "Cf"], [1, 1000]):
        for i, (case, label) in enumerate(labels.items()):
            data = samples[(samples.case == case) & (samples.quantity == quantity)].sort_values("x_L")
            if len(data):
                axis.plot(data.x_L, scale * data.cauchy, label=label,
                          **series_encoding(i, len(data), style=STYLE))
        ref = pd.read_csv(next((ROOT / "reference").glob(quantity.lower() + "_*")), comment="#")
        axis.plot(ref.x_L, scale * ref[quantity], linestyle="none", marker="x", color="black",
                  markersize=5, label="Huang et al.", zorder=4)
        for bounds in [(0.212, 0.297), (0.874, 0.921)]:
            axis.axvspan(*bounds, color="0.93", linewidth=0, zorder=0)
    axes[0].set_ylabel(r"$C_p$")
    axes[1].set(xlabel=r"$x/L$", ylabel=r"$10^3 C_f$", xlim=(0, 1))
    axes[1].set_ylim(bottom=0)
    axes[1].yaxis.set_major_locator(MultipleLocator(1))
    fig.legend(*axes[1].get_legend_handles_labels(), loc="outside lower center", ncols=2, frameon=False)
    save(fig, "meridian")


def vortex():
    data = pd.read_csv(ROOT / "figures/vortex-space-time.csv").sort_values("h")
    fig, ax = plt.subplots(figsize=(6, 4), layout="constrained")
    for i, (name, label) in enumerate([("velocity_l2", "Velocity"), ("pressure_l2", "Pressure")]):
        ax.loglog(data.h, data[name], label=label, **series_encoding(i, len(data), style=STYLE))
    ax.loglog(data.h, 0.2 * data.pressure_l2.iloc[0] * (data.h / data.h.iloc[0])**4,
              color="0.35", linestyle=":", label=r"$h^4$")
    ax.set(xlabel=r"$h$", ylabel=r"$L_2$ error")
    ax.xaxis.set_major_locator(FixedLocator(data.h))
    ax.xaxis.set_major_formatter(FuncFormatter(lambda x, _: f"{x:g}"))
    ax.tick_params(axis="x", which="minor", labelbottom=False)
    ax.legend(frameon=False)
    save(fig, "vortex-space-time")


def cuda():
    data = pd.read_csv(ROOT / "evidence/timings.csv").set_index("tag")
    times = [data.loc[tag, "wall_ms"] for tag in ("base", "cta128-r1", "scalar-stock-cta128",
                                                   "scalar-warp-cta128")] + [773.848]
    labels = ["Baseline", "CTA face flux", "+ SST Jacobian", "+ warp matvec", "Published routing"]
    fig, ax = plt.subplots(figsize=(6, 3.5), layout="constrained")
    ax.barh(labels, times, color=STYLE.colors[0], height=0.65)
    ax.invert_yaxis()
    ax.set(xlabel="Time per nonlinear update [ms]", xlim=(0, 1250))
    for i, value in enumerate(times):
        ax.text(value + 12, i, f"{value:,.0f}", va="center")
    save(fig, "cuda")


def p3_history():
    data = pd.read_csv(ROOT / "evidence/SUBOFF_P3_Q3__from-update-6000__production-fp32-b.csv")
    fig, ax = plt.subplots(figsize=(6, 4), layout="constrained")
    ax.semilogy(data.iteration, data.residual_target_ratio, **series_encoding(0, len(data), style=STYLE))
    ax.set(xlabel="Nonlinear correction", ylabel="Velocity residual / stopping tolerance")
    save(fig, "p3-steady-history")


if __name__ == "__main__":
    meridian()
    vortex()
    cuda()
    p3_history()
