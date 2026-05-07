# Deploying the featured backend on OCI Ampere

This guide covers provisioning the instance, opening the right port, running the server, and optionally pointing a domain at it.

---

## 1. Provision the instance

Log into the OCI console at cloud.oracle.com and go to **Compute > Instances > Create Instance**.

- Image: **Ubuntu 22.04 Minimal** (ARM-compatible)
- Shape: **VM.Standard.A1.Flex** (Ampere, free tier eligible)
- Assign a public IP under Networking > Primary VNIC

Download the SSH key pair the console generates. You will need the private key to connect.

---

## 2. SSH into the instance

```
ssh -i ~/path/to/your-key.pem ubuntu@<your-public-ip>
```

---

## 3. Install Node.js

The featured backend requires Node 18 or later. The Ubuntu package repos usually have an older version, so use the NodeSource setup script:

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
node -v   # should print v20.x
```

---

## 4. Copy the backend files

From your local machine:

```bash
scp -i ~/path/to/your-key.pem -r /path/to/ComputerCraft/SX-Music/backend ubuntu@<your-public-ip>:/opt/sx-music
```

Or clone the whole repo on the server and navigate into the backend folder.

---

## 5. Install dependencies and test

```bash
cd /opt/sx-music
npm install
node featured.js
```

You should see:

```
SX-Music featured API listening on port 3000
```

Press Ctrl+C for now, we will set it up properly next.

---

## 6. Open port 3000 in OCI ingress rules

By default OCI blocks all inbound traffic except SSH.

1. In the OCI console go to **Networking > Virtual Cloud Networks**.
2. Click your VCN, then **Security Lists** (or **Network Security Groups** if you use those).
3. Click **Add Ingress Rules**.
4. Fill in:

| Field | Value |
|-------|-------|
| Source Type | CIDR |
| Source CIDR | 0.0.0.0/0 |
| IP Protocol | TCP |
| Destination Port Range | 3000 |

5. Click Add Ingress Rules to save.

You also need to allow it through the OS-level firewall:

```bash
sudo iptables -I INPUT -p tcp --dport 3000 -j ACCEPT
sudo netfilter-persistent save
```

If `netfilter-persistent` is not installed:

```bash
sudo apt install -y iptables-persistent
```

---

## 7. Run the backend persistently with PM2

PM2 keeps the process alive after you log out and restarts it if it crashes.

```bash
sudo npm install -g pm2
cd /opt/sx-music
pm2 start featured.js --name sx-music-featured
pm2 save
pm2 startup
```

Run the command that `pm2 startup` prints (it will look something like `sudo env PATH=... pm2 startup systemd -u ubuntu --hp /home/ubuntu`).

After that the server will start automatically on every reboot.

Useful PM2 commands:

```bash
pm2 status                        # see if it is running
pm2 logs sx-music-featured        # live logs
pm2 restart sx-music-featured     # restart after code changes
pm2 stop sx-music-featured        # stop
```

---

## 8. Test the endpoint from your local machine

```bash
curl http://<your-public-ip>:3000/featured
```

You should get a JSON array of tracks. If you get a connection refused, double-check the ingress rule and iptables step above.

```bash
curl http://<your-public-ip>:3000/health
# {"status":"ok"}
```

---

## 9. Point a domain at the server (optional)

If you have a domain, go to your DNS provider and add an **A record**:

| Name | Type | Value |
|------|------|-------|
| music-api | A | `<your-public-ip>` |

TTL can be 300 seconds (5 min) so changes propagate fast.

After it propagates you can use `http://music-api.yourdomain.com:3000/featured` as your `FEATURED_API` value. If you want to drop the port number entirely, set up a reverse proxy with nginx (see below).

---

## 10. Use nginx to proxy on port 80 (optional but clean)

Instead of exposing port 3000 directly you can put nginx in front so the URL is just `http://music-api.yourdomain.com/featured`.

```bash
sudo apt install -y nginx
```

Create `/etc/nginx/sites-available/sx-music`:

```nginx
server {
    listen 80;
    server_name music-api.yourdomain.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

Enable it:

```bash
sudo ln -s /etc/nginx/sites-available/sx-music /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

Open port 80 in the OCI ingress rules the same way you opened 3000.

Then in `music.lua` set:

```lua
local FEATURED_API = "http://music-api.yourdomain.com/featured"
```

---

## 11. Update music.lua

Open `SX-Music/music.lua` and change line 12:

```lua
local FEATURED_API = "http://<your-public-ip>:3000/featured"
-- or if you set up nginx:
local FEATURED_API = "http://music-api.yourdomain.com/featured"
```

Commit and push so the install script pulls the updated version.
