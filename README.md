# Bluetooth-Demo-App

The project contains 2 apps: Sender and Receiver.

Both work in 2 mode: iBeacon and Bluetooth LE (there's a switch).

### Sender

In iBeacon mode, Sender app sends an iBeacon signal, changing its `minor` value between 0 and 1 every 10 seconds.

In BLE mode, Sender app displays a service that has a single value – the same, either 0 or 1, changing it every 10 seconds.

### Receiver

In iBeacon mode, Receiver watches the iBeacon signal end every 4 second, if conditions met, sends an HTTP request.
Conditions are: beacon minor value is 1 and the distance to the beacon is 0.5m or less.

In BLE mode it connects to the sender every 4 seconds, checks its value and, if it is 1, sends the same HTTP request.

When it receives a response to the HTTP request, it displays an animation and, in BLE mode, sends response to the Sender.

When you minimize the app and then open it again, it displays a blue splash screen for 5 seconds before restoring bluetooth monitoring.

### How to run

There are two schemes in the project, Sender and Receiver. The apps only work with each other. 
Just run them at the same time and enjoy.

Both apps have a switch between iBeacon mode and BLE mode.

### Video 

<iframe width="560" height="315" src="https://www.youtube.com/embed/A3yp2jNX3SU" frameborder="0" allowfullscreen></iframe>
