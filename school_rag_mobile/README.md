# Connect Mobile App to Local Web Server

When running the application on a physical phone, `localhost` or `127.0.0.1` refers to the mobile device itself, NOT your PC running the FastAPI server. 

To bridge the connection over Wi-Fi, you must use your PC's actual IPv4 address.

## Part 1: Finding Your PC's IP Address
1. Open PowerShell or Command Prompt on Windows.
2. Run the command: `ipconfig`
3. Look for the adapter connected to your Wi-Fi (e.g., "Wireless LAN adapter Wi-Fi").
4. Note the **IPv4 Address**. It usually looks like `192.168.1.X` or `10.0.0.X`.

## Part 2: Starting the FastAPI Server
Instead of binding to localhost, tell Uvicorn to accept incoming connections from any device on your local network by using `0.0.0.0`:
```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```
(*Note: Ensure your Windows Firewall allows incoming Python/Uvicorn TCP connections on port 8000.*)

## Part 3: Updating the Flutter App
1. Open `lib/services/api_service.dart`.
2. Locate the line:
   ```dart
   static const String baseUrl = "http://10.0.2.2:8000"; 
   ```
3. Change `10.0.2.2` to your actual IP Address. For example:
   ```dart
   static const String baseUrl = "http://192.168.1.15:8000";
   ```
4. Save the file. Ensure both your Phone and your PC are connected to the exact same Wi-Fi network.

## Run the Flutter App
With a physical phone plugged in via USB (USB debugging enabled), run:
```bash
flutter run
```
