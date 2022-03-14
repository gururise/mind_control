from PySide2 import QtCore, QtWidgets
from equalizer_bar import EqualizerBar

import random
import math
import socket
import threading
from struct import *

# This assumes BeamNG is running on the local machine
# The BeamNG UDP server needs to be enabled in the settings
localIP = "127.0.0.1"
localPort = 4444
bufferSize = 4096
x_acc = 0

# The IP Address and Port # of the GVS Device
serverAddressPort = ("192.168.1.205", 10000)

app = QtWidgets.QApplication([])
table = QtWidgets.QTableWidget(18, 2)
table.setHorizontalHeaderLabels(["Data","Value"])
table.setItem(0, 0, QtWidgets.QTableWidgetItem("velX"))
table.setItem(1, 0, QtWidgets.QTableWidgetItem("velY"))
table.setItem(2, 0, QtWidgets.QTableWidgetItem("velZ"))
table.setItem(3, 0, QtWidgets.QTableWidgetItem("accX"))
table.setItem(4, 0, QtWidgets.QTableWidgetItem("accY"))
table.setItem(5, 0, QtWidgets.QTableWidgetItem("accZ"))
table.setItem(6, 0, QtWidgets.QTableWidgetItem("upVecX"))
table.setItem(7, 0, QtWidgets.QTableWidgetItem("upVecY"))
table.setItem(8, 0, QtWidgets.QTableWidgetItem("upVecZ"))
table.setItem(9, 0, QtWidgets.QTableWidgetItem("rollPos"))
table.setItem(10, 0, QtWidgets.QTableWidgetItem("pitchPos"))
table.setItem(11, 0, QtWidgets.QTableWidgetItem("yawPos"))
table.setItem(12, 0, QtWidgets.QTableWidgetItem("rollRate"))
table.setItem(13, 0, QtWidgets.QTableWidgetItem("pitchRate"))
table.setItem(14, 0, QtWidgets.QTableWidgetItem("yawRate"))
table.setItem(15, 0, QtWidgets.QTableWidgetItem("rollAcc"))
table.setItem(16, 0, QtWidgets.QTableWidgetItem("pitchAcc"))
table.setItem(17, 0, QtWidgets.QTableWidgetItem("yawAcc"))
rdata = None


class Window(QtWidgets.QMainWindow):

    def __init__(self):
        super().__init__()

        layout = QtWidgets.QVBoxLayout()
        window = QtWidgets.QWidget()

        #Equalizer Widget
        self.equalizer = EqualizerBar(2, ['#0C0786', '#40039C', '#6A00A7', '#8F0DA3', '#B02A8F', '#CA4678', '#E06461',
                                          '#F1824C', '#FCA635', '#FCCC25', '#EFF821'])
        self.equalizer.setDecay(0)
        self.equalizer.setBarPadding(25)
        self.equalizer.setRange(0,12)

        layout.addWidget(self.equalizer)
        layout.addWidget(table)


        window.setLayout(layout)
        self.setCentralWidget(window)

        # Create a UDP socket at client side
        self.UDPClientSocket = socket.socket(family=socket.AF_INET, type=socket.SOCK_DGRAM)

        # Call update_values every 100ms
        self._timer = QtCore.QTimer()
        self._timer.setInterval(100)
        self._timer.timeout.connect(self.update_values)
        self._timer.start()

        thread = threading.Thread(target=self.udp_handler)
        thread.start()

    def update_values(self):
        global rdata

        xval = rdata[7] - math.sin(rdata[13])*9.8

        if (xval < 0):
            self.equalizer.setValues([0, -xval])
        else:
            self.equalizer.setValues([xval, 0])

        # send data to GVS Device
        self.UDPClientSocket.sendto(str.encode("Y0:X"+str(xval)), serverAddressPort)

        if rdata != None:
            for x in range(4, 22):
                if (x == 7):
                    table.setItem(x-4, 1, QtWidgets.QTableWidgetItem(str(round(xval, 3))))
                else:
                    table.setItem(x-4, 1, QtWidgets.QTableWidgetItem(str(round(rdata[x], 3))))

    def udp_handler(self):
        global x_acc
        global table
        global rdata

        msgFromServer = "MSG From UDP Client"
        bytesToSend = str.encode(msgFromServer)

        # Create a datagram socket
        self.UDPServerSocket = socket.socket(family=socket.AF_INET, type=socket.SOCK_DGRAM)

        # Bind to address and ip
        self.UDPServerSocket.bind((localIP, localPort))

        print("UDP server up and listening")
        # Listen for incoming datagrams
        while(True):
            data, address = self.UDPServerSocket.recvfrom(bufferSize)
            rdata = unpack("4sfffffffffffffffffffff", data)
            #clientMsg = "Message from Client:{}".format(data)
            clientIP = "Client IP Address:{}".format(address)

            # print(clientMsg)
            print("accX: " + str(rdata[7]))

            #self.calc_x_acc()
            #print(clientIP)

            # Sending a reply to client
            #self.UDPServerSocket.sendto(bytesToSend, address)


w = Window()
w.show()
app.exec_()
