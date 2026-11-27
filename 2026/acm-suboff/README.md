# Artificial compressibility in Cauchy and the SUBOFF AFF8 benchmark

Figures, station data, timing summaries and allocation snapshots for the HarrysNotes article. The two inputs in `configs/` describe the AFF8-02 direct P1 startup and P2/Q3 continuation. The P3 residual plot illustrates a failed continuation.

Open `snapshots/allocation.html` in a browser after downloading it to explore the AFF8-02 P2/Q3 allocations before and after the CUDA changes. The same viewer is embedded in the article. The two JSON ledgers separate Runtime capacity, AmgX-owned allocations and borrowed matrix storage.

The pressure and friction tables in `reference/` retain their source headers. The experimental points were digitized from figures 9 and 13 of Huang et al. (1994). See [the digitization record](https://zenodo.org/records/22692726).

The source report is at plan revision `f26ea669312c4ddf337f0e756fb972f890702bbb`. SHA256SUMS covers the files in this public companion directory.
