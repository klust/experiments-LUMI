import numpy as np
import matplotlib.pyplot as plt

ngpus, times = np.loadtxt("results.txt", unpack=True)

for i, j in zip(ngpus, times):
    print(f"ngpus {i:3.0f}  sec. {j:8.4f}  su {times[0]/j:.2f}")

fig, ax = plt.subplots()

ax.plot(ngpus, ngpus/ngpus[0], ls="--", c="black", alpha=0.5, label="Ideal")
ax.plot(ngpus, times[0]/times, lw=2, marker="o", label="Speed-Up")

ax.set_xlabel("Number of GPUs")
ax.set_ylabel("Speed Up")

ax.legend()

plt.savefig("speed-up.png")
