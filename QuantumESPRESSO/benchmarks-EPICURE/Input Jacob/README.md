# Input from Jacob

In bijlage het Slurm script voor QE op GPU. Om te schalen naar meerdere nodes: 
naast de `--nodes` parameter ook de `-nk` parameter in de laatste lijn aanpassen. 
`FI_CXI_RX_MATCH_MODE=software` is overgenomen uit het voorbeeld dat ik gekregen 
heb van Laura, dus ik weet niet hoe nodig/nuttig dat is. De inputfiles vind je hier: 
[Execution/Data/Data_qe · main · Epicure / EPICURE BENCHMARK · GitLab](https://opencode.it4i.eu/epicure/epicure-benchmark/-/tree/main/Execution/Data/Data_qe).
 
De job draait in deze config in een dikke 40 minuten op 1 node. 
De relevante termination condition in de .in file is 
`conv_thr        = 1.0d-8`, die behaald wordt na ~50 iteraties. 
Je kunt het sneller laten terminaten door die threshold hoger te zetten, 
maar da's nogal vervelend te tunen. 
Ik denk dat je ook `maxiter=200` twee lijntjes eronder op minder dan 50 kunt instellen voor snellere runs, 
maar heb dat zelf niet geprobeerd, dus ben niet 100% zeker dat dat de juiste parameter is.

 
Voor de EPICURE benchmarks specifiek draaien we voor 1 tem 16 nodes, met deze resultaten voor LUMI: 
[Results/LUMI/GPU/QE · main · Epicure / EPICURE BENCHMARK · GitLab](https://opencode.it4i.eu/epicure/epicure-benchmark/-/tree/main/Results/LUMI/GPU/QE).

 