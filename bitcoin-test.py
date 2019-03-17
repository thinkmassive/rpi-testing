import time
from gpiozero import CPUTemperature, LoadAverage, DiskUsage
from bitcoinrpc.authproxy import AuthServiceProxy, JSONRPCException

max_blockcount = 300000
delay = 10
rpc_user="raspibolt"
rpc_password="PASSWORD"

# rpc_user and rpc_password are set in the bitcoin.conf file
rpc_connection = AuthServiceProxy("http://%s:%s@127.0.0.1:8332"%(rpc_user, rpc_password))
blockcount = rpc_connection.getblockcount()

while blockcount < max_blockcount:
  timestamp = time.time()
  cpu = CPUTemperature().temperature
  load = LoadAverage(minutes=1).load_average
  disk = DiskUsage().usage
  blockcount = rpc_connection.getblockcount()
  print('{}% {}% {}% {}% {}%'.format(timestamp, cpu, load, disk, blockcount))
  time.sleep(delay)


