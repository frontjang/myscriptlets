import serial
import time
ser = serial.Serial('COM4', 9600, timeout=0)
 
while 1:
	
	s = ser.readline()
	#print(s)
	ss= s.rstrip().decode()
	
	if len(ss) != 0:
		print(float(ss))
	time.sleep(0.1)

