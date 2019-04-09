# NG_Morbidostat
Code to operate the NG morbidostat. 

The code ‘ExperimentController.m’ was the main class file, which ran the whole experiment by controlling ‘PumpController.m’, ‘DataReceiver.m’ and ‘DataMonitor.m’ in parallel. ‘PumpController.m’ controlled the 30 peristaltic pumps and the 16-channel suction pump. The file ‘DataReceiver.m’ contained the code that read the voltage measurements by the photo-detectors. It converted the voltage readings automatically to turbidity measurements, depending on the calibration parameters. The file ‘DataMonitor.m’ monitored the real-time data to the user while the experiment was running.

(Whole code was based on the code Toprak et al. used in their morbidostat, which was written by M. Sadik Yildiz)
