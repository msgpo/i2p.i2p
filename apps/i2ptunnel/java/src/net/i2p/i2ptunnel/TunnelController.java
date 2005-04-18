package net.i2p.i2ptunnel;

import java.io.IOException;
import java.io.File;
import java.io.FileOutputStream;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Properties;
import java.util.Random;

import net.i2p.I2PAppContext;
import net.i2p.I2PException;
import net.i2p.client.I2PClient;
import net.i2p.client.I2PClientFactory;
import net.i2p.client.I2PSession;
import net.i2p.data.Destination;
import net.i2p.util.I2PThread;
import net.i2p.util.Log;

/**
 * Coordinate the runtime operation and configuration of a tunnel.  
 * These objects are bundled together under a TunnelControllerGroup where the
 * entire group is stored / loaded from a single config file.
 *
 */
public class TunnelController implements Logging {
    private Log _log;
    private Properties _config;
    private I2PTunnel _tunnel;
    private List _messages;
    private List _sessions;
    private boolean _running;
    private boolean _starting;
    
    /**
     * Create a new controller for a tunnel out of the specific config options.
     * The config may contain a large number of options - only ones that begin in
     * the prefix should be used (and, in turn, that prefix should be stripped off
     * before being interpreted by this controller)
     * 
     * @param config original key=value mapping
     * @param prefix beginning of key values that are relevent to this tunnel
     */
    public TunnelController(Properties config, String prefix) {
        this(config, prefix, true);
    }
    /**
     * 
     * @param createKey for servers, whether we want to create a brand new destination
     *                  with private keys at the location specified or not (does not
     *                  overwrite existing ones)
     */
    public TunnelController(Properties config, String prefix, boolean createKey) {
        _tunnel = new I2PTunnel();
        _log = I2PAppContext.getGlobalContext().logManager().getLog(TunnelController.class);
        setConfig(config, prefix);
        _messages = new ArrayList(4);
        _running = false;
        if (createKey && ("server".equals(getType()) || "httpserver".equals(getType())) )
            createPrivateKey();
        _starting = getStartOnLoad();
    }
    
    private void createPrivateKey() {
        I2PClient client = I2PClientFactory.createClient();
        String filename = getPrivKeyFile();
        if ( (filename == null) || (filename.trim().length() <= 0) ) {
            log("No filename specified for the private key");
            return;
        }
        
        File keyFile = new File(getPrivKeyFile());
        if (keyFile.exists()) {
            log("Not overwriting existing private keys in " + keyFile.getAbsolutePath());
            return;
        } else {
            File parent = keyFile.getParentFile();
            if ( (parent != null) && (!parent.exists()) )
                parent.mkdirs();
        }
        FileOutputStream fos = null;
        try {
            fos = new FileOutputStream(keyFile);
            Destination dest = client.createDestination(fos);
            String destStr = dest.toBase64();
            log("Private key created and saved in " + keyFile.getAbsolutePath());
            log("New destination: " + destStr);
        } catch (I2PException ie) {
            if (_log.shouldLog(Log.ERROR))
                _log.error("Error creating new destination", ie);
            log("Error creating new destination: " + ie.getMessage());
        } catch (IOException ioe) {
            if (_log.shouldLog(Log.ERROR))
                _log.error("Error creating writing the destination to " + keyFile.getAbsolutePath(), ioe);
            log("Error writing the keys to " + keyFile.getAbsolutePath());
        } finally {
            if (fos != null) try { fos.close(); } catch (IOException ioe) {}
        }
    }
    
    public void startTunnelBackground() {
        if (_running) return;
        _starting = true;
        new I2PThread(new Runnable() { public void run() { startTunnel(); } }).start();
    }
    
    /**
     * Start up the tunnel (if it isn't already running)
     *
     */
    public void startTunnel() {
        _starting = true;
        try {
            doStartTunnel();
        } catch (Exception e) {
            _log.error("Error starting up the tunnel", e);
            log("Error starting up the tunnel - " + e.getMessage());
        }
        _starting = false;
    }
    private void doStartTunnel() {
        if (_running) {
            if (_log.shouldLog(Log.INFO))
                _log.info("Already running");
            log("Tunnel " + getName() + " is already running");
            return;
        }
        String type = getType(); 
        if ( (type == null) || (type.length() <= 0) ) {
            if (_log.shouldLog(Log.WARN))
                _log.warn("Cannot start the tunnel - no type specified");
            return;
        }
        if ("httpclient".equals(type)) {
            startHttpClient();
        } else if ("client".equals(type)) {
            startClient();
        } else if ("server".equals(type)) {
            startServer();
        } else if ("httpserver".equals(type)) {
            startHttpServer();
        } else {
            if (_log.shouldLog(Log.ERROR))
                _log.error("Cannot start tunnel - unknown type [" + type + "]");
        }
    }
    
    private void startHttpClient() {
        setI2CPOptions();
        setSessionOptions();
        setListenOn();
        String listenPort = getListenPort();
        String proxyList = getProxyList();
        String sharedClient = getSharedClient();
        if (proxyList == null)
            _tunnel.runHttpClient(new String[] { listenPort, sharedClient }, this);
        else
            _tunnel.runHttpClient(new String[] { listenPort, sharedClient, proxyList }, this);
        acquire();
        _running = true;
    }
    
    /** 
     * Note the fact that we are using some sessions, so that they dont get
     * closed by some other tunnels
     */
    private void acquire() {
        List sessions = _tunnel.getSessions();
        if (sessions != null) {
            for (int i = 0; i < sessions.size(); i++) {
                I2PSession session = (I2PSession)sessions.get(i);
                TunnelControllerGroup.getInstance().acquire(this, session);
            }
            _sessions = sessions;
        } else {
            _log.error("No sessions to acquire?");
        }
    }
    
    /** 
     * Note the fact that we are no longer using some sessions, and if
     * no other tunnels are using them, close them.
     */
    private void release() {
        if (_sessions != null) {
            for (int i = 0; i < _sessions.size(); i++) {
                I2PSession s = (I2PSession)_sessions.get(i);
                TunnelControllerGroup.getInstance().release(this, s);
            }
        } else {
            _log.error("No sessions to release?");
        }
    }
    
    private void startClient() {
        setI2CPOptions();
        setSessionOptions();
        setListenOn();
        String listenPort = getListenPort(); 
        String dest = getTargetDestination();
        String sharedClient = getSharedClient();
        _tunnel.runClient(new String[] { listenPort, dest, sharedClient }, this);
        acquire();
        _running = true;
    }

    private void startServer() {
        setI2CPOptions();
        setSessionOptions();
        String targetHost = getTargetHost(); 
        String targetPort = getTargetPort(); 
        String privKeyFile = getPrivKeyFile(); 
        _tunnel.runServer(new String[] { targetHost, targetPort, privKeyFile }, this);
        acquire();
        _running = true;
    }
    
    private void startHttpServer() {
        setI2CPOptions();
        setSessionOptions();
        String targetHost = getTargetHost(); 
        String targetPort = getTargetPort(); 
        String spoofedHost = getSpoofedHost(); 
        String privKeyFile = getPrivKeyFile(); 
        _tunnel.runHttpServer(new String[] { targetHost, targetPort, spoofedHost, privKeyFile }, this);
        acquire();
        _running = true;
    }
    
    private void setListenOn() {
        String listenOn = getListenOnInterface();
        if ( (listenOn != null) && (listenOn.length() > 0) ) {
            _tunnel.runListenOn(new String[] { listenOn }, this);
        }
    }
    
    private void setSessionOptions() {
        List opts = new ArrayList();
        for (Iterator iter = _config.keySet().iterator(); iter.hasNext(); ) {
            String key = (String)iter.next();
            String val = _config.getProperty(key);
            if (key.startsWith("option.")) {
                key = key.substring("option.".length());
                opts.add(key + "=" + val);
            }
        }
        String args[] = new String[opts.size()];
        for (int i = 0; i < opts.size(); i++)
            args[i] = (String)opts.get(i);
        _tunnel.runClientOptions(args, this);
    }
    
    private void setI2CPOptions() {
        String host = getI2CPHost();
        if ( (host != null) && (host.length() > 0) ) 
            _tunnel.host = host;
        // woohah, special casing for people with ipv6/etc
        if ("localhost".equals(_tunnel.host)) 
            _tunnel.host = "127.0.0.1";
        String port = getI2CPPort();
        if ( (port != null) && (port.length() > 0) ) {
            try {
                int portNum = Integer.parseInt(port);
                _tunnel.port = String.valueOf(portNum);
            } catch (NumberFormatException nfe) {
                _tunnel.port = "7654";
            }
        } else {
            _tunnel.port = "7654";
        }
    }
    
    public void stopTunnel() {
        _tunnel.runClose(new String[] { "forced", "all" }, this);
        release();
        _running = false;
    }
    
    public void restartTunnel() {
        stopTunnel();
        startTunnel();
    }
    
    public void setConfig(Properties config, String prefix) {
        Properties props = new Properties();
        for (Iterator iter = config.keySet().iterator(); iter.hasNext(); ) {
            String key = (String)iter.next();
            String val = config.getProperty(key);
            if (key.startsWith(prefix)) {
                key = key.substring(prefix.length());
                props.setProperty(key, val);
                if (_log.shouldLog(Log.DEBUG))
                    _log.debug("Set prop [" + key + "] to [" + val + "]");
            }
        }
        _config = props;
    }
    public Properties getConfig(String prefix) { 
        Properties rv = new Properties();
        for (Iterator iter = _config.keySet().iterator(); iter.hasNext(); ) {
            String key = (String)iter.next();
            String val = _config.getProperty(key);
            rv.setProperty(prefix + key, val);
        }
        return rv;
    }

    public String getType() { return _config.getProperty("type"); }
    public String getName() { return _config.getProperty("name"); }
    public String getDescription() { return _config.getProperty("description"); }
    public String getI2CPHost() { return _config.getProperty("i2cpHost"); }
    public String getI2CPPort() { return _config.getProperty("i2cpPort"); }
    public String getClientOptions() {
        StringBuffer opts = new StringBuffer(64);
        for (Iterator iter = _config.keySet().iterator(); iter.hasNext(); ) {
            String key = (String)iter.next();
            String val = _config.getProperty(key);
            if (key.startsWith("option.")) {
                key = key.substring("option.".length());
                if (opts.length() > 0) opts.append(' ');
                opts.append(key).append('=').append(val);
            }
        }
        return opts.toString();
    }
    public String getListenOnInterface() { return _config.getProperty("interface"); }
    public String getTargetHost() { return _config.getProperty("targetHost"); }
    public String getTargetPort() { return _config.getProperty("targetPort"); }
    public String getSpoofedHost() { return _config.getProperty("spoofedHost"); }
    public String getPrivKeyFile() { return _config.getProperty("privKeyFile"); }
    public String getListenPort() { return _config.getProperty("listenPort"); }
    public String getTargetDestination() { return _config.getProperty("targetDestination"); }
    public String getProxyList() { return _config.getProperty("proxyList"); }
    public String getSharedClient() { return _config.getProperty("sharedClient", "true"); }
    public boolean getStartOnLoad() { return "true".equalsIgnoreCase(_config.getProperty("startOnLoad", "true")); }
    public String getMyDestination() {
        if (_tunnel != null) {
            List sessions = _tunnel.getSessions();
            for (int i = 0; i < sessions.size(); i++) {
                I2PSession session = (I2PSession)sessions.get(i);
                Destination dest = session.getMyDestination();
                if (dest != null)
                    return dest.toBase64();
            }
        }
        return null;
    }
    
    public boolean getIsRunning() { return _running; }
    public boolean getIsStarting() { return _starting; }
    
    public void getSummary(StringBuffer buf) {
        String type = getType();
        if ("httpclient".equals(type))
            getHttpClientSummary(buf);
        else if ("client".equals(type))
            getClientSummary(buf);
        else if ("server".equals(type))
            getServerSummary(buf);
        else if ("httpserver".equals(type))
            getHttpServerSummary(buf);
        else
            buf.append("Unknown type ").append(type);
    }
    
    private void getHttpClientSummary(StringBuffer buf) {
        String description = getDescription();
        if ( (description != null) && (description.trim().length() > 0) )
            buf.append("<i>").append(description).append("</i><br />\n");
        buf.append("HTTP proxy listening on port ").append(getListenPort());
        String listenOn = getListenOnInterface();
        if ("0.0.0.0".equals(listenOn)) 
            buf.append(" (reachable by any machine)");
        else if ("127.0.0.1".equals(listenOn))
            buf.append(" (reachable locally only)");
        else
            buf.append(" (reachable at the ").append(listenOn).append(" interface)");
        buf.append("<br />\n");
        String proxies = getProxyList();
        if ( (proxies == null) || (proxies.trim().length() <= 0) )
            buf.append("Outproxy: default [squid.i2p]<br />\n");
        else
            buf.append("Outproxy: ").append(proxies).append("<br />\n");
        getOptionSummary(buf);
    }
    
    private void getClientSummary(StringBuffer buf) {
        String description = getDescription();
        if ( (description != null) && (description.trim().length() > 0) )
            buf.append("<i>").append(description).append("</i><br />\n");
        buf.append("Client tunnel listening on port ").append(getListenPort());
        buf.append(" pointing at ").append(getTargetDestination());
        String listenOn = getListenOnInterface();
        if ("0.0.0.0".equals(listenOn)) 
            buf.append(" (reachable by any machine)");
        else if ("127.0.0.1".equals(listenOn))
            buf.append(" (reachable locally only)");
        else
            buf.append(" (reachable at the ").append(listenOn).append(" interface)");
        buf.append("<br />\n");
        getOptionSummary(buf);
    }
    
    private void getServerSummary(StringBuffer buf) {
        String description = getDescription();
        if ( (description != null) && (description.trim().length() > 0) )
            buf.append("<i>").append(description).append("</i><br />\n");
        buf.append("Server tunnel pointing at port ").append(getTargetPort());
        buf.append(" on ").append(getTargetHost());
        buf.append("<br />\n");
        buf.append("Private destination loaded from ").append(getPrivKeyFile()).append("<br />\n");
        getOptionSummary(buf);
    }
    
    private void getHttpServerSummary(StringBuffer buf) {
        String description = getDescription();
        if ( (description != null) && (description.trim().length() > 0) )
            buf.append("<i>").append(description).append("</i><br />\n");
        buf.append("Server tunnel pointing at port ").append(getTargetPort());
        buf.append(" on ").append(getTargetHost());
        buf.append(" for the site ").append(getSpoofedHost());
        buf.append("<br />\n");
        buf.append("Private destination loaded from ").append(getPrivKeyFile()).append("<br />\n");
        getOptionSummary(buf);
    }
    
    private void getOptionSummary(StringBuffer buf) {
        String opts = getClientOptions();
        if ( (opts != null) && (opts.length() > 0) )
            buf.append("Network options: ").append(opts).append("<br />\n");
        if (_running) {
            List sessions = _tunnel.getSessions();
            for (int i = 0; i < sessions.size(); i++) {
                I2PSession session = (I2PSession)sessions.get(i);
                Destination dest = session.getMyDestination();
                if (dest != null) {
                    buf.append("Destination hash: ").append(dest.calculateHash().toBase64()).append("<br />\n");
                    if ( ("server".equals(getType())) || ("httpserver".equals(getType())) ) {
                        buf.append("Full destination: ");
                        buf.append("<input type=\"text\" size=\"10\" onclick=\"this.select();\" ");
                        buf.append("value=\"").append(dest.toBase64()).append("\" />\n");
                        long val = new Random().nextLong();
                        if (val < 0) val = 0 - val;
                        buf.append("<br />You can <a href=\"http://temp").append(val);
                        buf.append(".i2p/?i2paddresshelper=").append(dest.toBase64()).append("\">view</a>");
                        buf.append(" it in a browser (only when you're using the eepProxy)\n");
                        buf.append("<br />If you are going to share this on IRC, you need to split it up:<br />\n");
                        String str = dest.toBase64();
                        buf.append(str.substring(0, str.length()/2)).append("<br />\n");
                        buf.append(str.substring(str.length()/2)).append("<br />\n");
                        buf.append("You can also post it to <a href=\"http://forum.i2p/viewforum.php?f=16\">Eepsite announcement forum</a><br />");
                    }
                }
            }
        }
    }
    
    public void log(String s) {
        synchronized (this) {
            _messages.add(s);
            while (_messages.size() > 10)
                _messages.remove(0);
        }
        if (_log.shouldLog(Log.INFO))
            _log.info(s);
    }
    
    /**
     * Pull off any messages that the I2PTunnel has produced 
     *
     * @return list of messages pulled off (each is a String, earliest first)
     */
    public List clearMessages() { 
        List rv = null;
        synchronized (this) {
            rv = new ArrayList(_messages);
            _messages.clear();
        }
        return rv;
    }
}
