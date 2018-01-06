<%@page contentType="text/html" import="net.i2p.i2ptunnel.web.EditBean"
%><%@page trimDirectiveWhitespaces="true"
%><?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<jsp:useBean class="net.i2p.i2ptunnel.web.EditBean" id="editBean" scope="request" />
<jsp:useBean class="net.i2p.i2ptunnel.web.Messages" id="intl" scope="request" />
<% String tun = request.getParameter("tunnel");
   int curTunnel = -1;
   if (tun != null) {
     try {
       curTunnel = Integer.parseInt(tun);
     } catch (NumberFormatException nfe) {
       curTunnel = -1;
     }
   }
%>

<%
    response.setHeader("Content-Security-Policy", "default-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'");
%>

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
    <title><%=intl._t("Hidden Services Manager")%> - <%=intl._t("Edit Client Tunnel")%></title>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <meta http-equiv="Content-Type" content="application/xhtml+xml; charset=UTF-8" />
    <link href="/themes/console/images/favicon.ico" type="image/x-icon" rel="shortcut icon" />

    <% if (editBean.allowCSS()) {
  %><link rel="icon" href="<%=editBean.getTheme()%>images/favicon.ico" />
    <link href="<%=editBean.getTheme()%>i2ptunnel.css?<%=net.i2p.CoreVersion.VERSION%>" rel="stylesheet" type="text/css" /> 
    <% }
  %>
<style type='text/css'>
input.default { width: 1px; height: 1px; visibility: hidden; }
</style>
<script src="/js/resetScroll.js" type="text/javascript"></script>
</head>
<body id="tunnelEditPage">

<%

  if (editBean.isInitialized()) {

%>
    <form method="post" action="list">

        <div class="panel">
                <%
                String tunnelTypeName;
                String tunnelType;
                if (curTunnel >= 0) {
                    tunnelTypeName = editBean.getTunnelType(curTunnel);
                    tunnelType = editBean.getInternalType(curTunnel);
                  %><h2><%=intl._t("Edit proxy settings")%> (<%=editBean.getTunnelName(curTunnel)%>)</h2><% 
                } else {
                    tunnelTypeName = editBean.getTypeName(request.getParameter("type"));
                    tunnelType = net.i2p.data.DataHelper.stripHTML(request.getParameter("type"));
                  %><h2><%=intl._t("New proxy settings")%></h2><% 
                } %>
                <input type="hidden" name="tunnel" value="<%=curTunnel%>" />
                <input type="hidden" name="nonce" value="<%=net.i2p.i2ptunnel.web.IndexBean.getNextNonce()%>" />
                <input type="hidden" name="type" value="<%=tunnelType%>" />
                <%
                // these are four keys that are generated automatically on first save,
                // and we want to persist in i2ptunnel.config, but don't want to
                // show clogging up the custom options form.
                String key = editBean.getKey1(curTunnel);
                if (key != null && key.length() > 0) { %>
                    <input type="hidden" name="key1" value="<%=key%>" />
                <% }
                key = editBean.getKey2(curTunnel);
                if (key != null && key.length() > 0) { %>
                    <input type="hidden" name="key2" value="<%=key%>" />
                <% }
                key = editBean.getKey3(curTunnel);
                if (key != null && key.length() > 0) { %>
                    <input type="hidden" name="key3" value="<%=key%>" />
                <% }
                key = editBean.getKey4(curTunnel);
                if (key != null && key.length() > 0) { %>
                    <input type="hidden" name="key4" value="<%=key%>" />
                <% } %>
                <input type="submit" class="default" name="action" value="Save changes" />

    <table id="clientTunnelEdit" class="tunnelConfig">
        <tr>
            <th>
                <%=intl._t("Name")%>
            </th>
            <th>
                <%=intl._t("Type")%>
            </th>
        </tr>
        <tr>
            <td>
                <input type="text" size="30" maxlength="50" name="name" title="<%=intl._t("Name of tunnel to be displayed on Tunnel Manager home page and the router console sidebar")%>" value="<%=editBean.getTunnelName(curTunnel)%>" class="freetext tunnelName" />
            </td>
            <td>
                <%=tunnelTypeName%>
            </td>
        </tr>

        <tr>
            <th>
                <%=intl._t("Description")%>
            </th>

            <th>
                <%=intl._t("Auto Start Tunnel")%>
            </th>
        </tr>

        <tr>
            <td>
                <input type="text" size="60" maxlength="80" name="nofilter_description" title="<%=intl._t("Description of tunnel to be displayed on Tunnel Manager home page")%>" value="<%=editBean.getTunnelDescription(curTunnel)%>" class="freetext tunnelDescription" />
            </td>

            <td>
                <label title="<%=intl._t("Enable this option to ensure this service is available when the router starts")%>"><input value="1" type="checkbox" name="startOnLoad"<%=(editBean.startAutomatically(curTunnel) ? " checked=\"checked\"" : "")%> class="tickbox" />
                <%=intl._t("Automatically start tunnel when router starts")%></label>
            </td>
        </tr>

        <tr>
            <th colspan="2">
         <% if ("streamrclient".equals(tunnelType)) { %>
                <%=intl._t("Target")%>
         <% } else { %>
                <%=intl._t("Access Point")%>
         <% } /* streamrclient */ %>
            </th>
        </tr>
        <tr>
            <td>
                <b><%=intl._t("Port")%>:</b>
                    <% String value = editBean.getClientPort(curTunnel);
                       if (value == null || "".equals(value.trim())) {
                           out.write(" <span class=\"required\"><font color=\"red\">(");
                           out.write(intl._t("required"));
                           out.write(")</font></span>");
                       }
                     %>
                <input type="text" size="6" maxlength="5" name="port" title="<%=intl._t("Specify the local port this service should be accessible from")%>" value="<%=editBean.getClientPort(curTunnel)%>" class="freetext port" placeholder="required" />
            </td>

         <%
            if ("streamrclient".equals(tunnelType)) { %>
            <td>
                <b><%=intl._t("Host")%>:</b>
                    <%
                       String targetHost = editBean.getTargetHost(curTunnel);
                       if (targetHost == null || "".equals(targetHost.trim())) {
                           out.write(" <span class=\"required\"><font color=\"red\">(");
                           out.write(intl._t("required"));
                           out.write(")</font></span>");
                       }
          %>

                <input type="text" size="20" id="targetHost" name="targetHost" title="<%=intl._t("Hostname or IP address of the target server")%>" value="<%=targetHost%>" class="freetext host" placeholder="required" />
            </td>
         <% } else { %>

            <td>
                <b><%=intl._t("Reachable by")%>:</b>

                <select id="reachableBy" name="reachableBy" title="<%=intl._t("Local interface (ip address) the client tunnel will be reachable from")%>" class="selectbox")%>">
              <%
                    String clientInterface = editBean.getClientInterface(curTunnel);
                    for (String ifc : editBean.interfaceSet()) {
                        out.write("<option value=\"");
                        out.write(ifc);
                        out.write('\"');
                        if (ifc.equals(clientInterface))
                            out.write(" selected=\"selected\"");
                        out.write('>');
                        out.write(ifc);
                        out.write("</option>\n");
                    }
              %>
                </select>
            </td>
         <% } /* streamrclient */ %>
        </tr>

         <% if ("client".equals(tunnelType) || "ircclient".equals(tunnelType)) {
          %>
        <tr>
            <th colspan="2">
                    <%=intl._t("Use SSL?")%>
            </th>
        </tr>
        <tr>
            <td colspan="2">
                <label title="<%=intl._t("If you are accessing a service on a remote I2P router, you may wish to connect with SSL to avoid traffic interception. The client application should be also be configured to use SSL.")%>"><input value="1" type="checkbox" name="useSSL" <%=(editBean.isSSLEnabled(curTunnel) ? " checked=\"checked\"" : "")%> class="tickbox" />
                <%=intl._t("Clients use SSL to connect to tunnel")%></label>
            </td>
        </tr>
         <% } /* tunnel types */ %>

            <% if ("httpclient".equals(tunnelType) || "connectclient".equals(tunnelType) || "sockstunnel".equals(tunnelType) || "socksirctunnel".equals(tunnelType)) {
          %>
        <tr>
            <th colspan="2">
                    <%=intl._t("Outproxies")%>
            </th>
        </tr>
        <tr>
            <td colspan="2">
                <input type="text" size="30" name="proxyList" title="<%=intl._t("Specify the .i2p address or destination (b32 or b64) of the outproxy here.")%>&nbsp;<%=intl._t("For a random selection from a pool, separate with commas e.g. server1.i2p,server2.i2p")%>" value="<%=editBean.getClientDestination(curTunnel)%>" class="freetext proxyList" />
            </td>
        </tr>

              <% if ("httpclient".equals(tunnelType)) {
                 %>
        <tr>
            <th colspan="2">
                       <%=intl._t("SSL Outproxies")%>
            </th>
        </tr>
        <tr>
            <td colspan="2">
                   <input type="text" size="30" name="sslProxies" title="<%=intl._t("Specify the .i2p address or destination (b32 or b64) of the outproxy here.")%>&nbsp;<%=intl._t("For a random selection from a pool, separate with commas e.g. server1.i2p,server2.i2p")%>" value="<%=editBean.getSslProxies(curTunnel)%>" class="freetext proxyList" />
            </td>
        </tr>

              <% }  // httpclient %>
        <tr>
            <th colspan="2">
                    <%=intl._t("Use Outproxy Plugin")%>

            </th>
        </tr>
        <tr>
            <td colspan="2">

                <label title="<%=intl._t("If an outproxy plugin is installed (e.g. Orchid), use this instead of any configured outproxies to access websites outside of I2P")%>"><input value="1" type="checkbox" name="useOutproxyPlugin" <%=(editBean.getUseOutproxyPlugin(curTunnel) ? " checked=\"checked\"" : "")%> class="tickbox" />
<%=intl._t("Use plugin instead of above-listed proxies if available")%></label>
            </td>
        </tr>
            <% } else if ("client".equals(tunnelType) || "ircclient".equals(tunnelType) || "streamrclient".equals(tunnelType)) {
          %>
        <tr>
            <th colspan="2">
                    <%=intl._t("Tunnel Destination")%>
            </th>
        </tr>
        <tr>
            <td colspan="2">
                    <% String value2 = editBean.getClientDestination(curTunnel);
                       if (value2 == null || "".equals(value2.trim())) {
                           out.write(" <span class=\"required\"><font color=\"red\">(");
                           out.write(intl._t("required"));
                           out.write(")</font></span>");
                       }
                     %>

                <input type="text" size="30" id="targetDestination" name="targetDestination" title="<%=intl._t("Specify the .i2p address or destination (b32 or b64) of the tunnel here.")%>&nbsp;<%=intl._t("For a random selection from a pool, separate with commas e.g. server1.i2p,server2.i2p")%>" value="<%=editBean.getClientDestination(curTunnel)%>" class="freetext destination" placeholder="required" />
                (<%=intl._t("name, name:port, or destination")%>
                     <% if ("streamrclient".equals(tunnelType)) { /* deferred resolution unimplemented in streamr client */ %>
                         - <%=intl._t("b32 not recommended")%>
                     <% } %> )
            </td>
        </tr>

         <% } %>

         <% if (!"streamrclient".equals(tunnelType)) { %>
        <tr>
            <th colspan="2">
                <%=intl._t("Shared Client")%>
            </th>
        </tr>
        <tr>
            <td colspan="2">
                <label title="<%=intl._t("Traffic from all clients with this feature enabled will be routed over the same set of tunnels. This will make profiling the tunnels by an adversary more difficult, but will link the clients together.")%>"><input value="true" type="checkbox" name="shared"<%=(editBean.isSharedClient(curTunnel) ? " checked=\"checked\"" : "")%> class="tickbox" />
                <%=intl._t("Share tunnels with other clients and irc/httpclients? (Change requires restart of client proxy tunnel)")%></label>
            </td>
        </tr>

         <% } // !streamrclient %>

         <% if ("ircclient".equals(tunnelType)) { %>
        <tr>
            <th colspan="2">
                    <%=intl._t("Enable DCC")%>
            </th>
        </tr>
        <tr>
            <td colspan="2">
                <label title="<%=intl._t("Enables direct chat and file transfers, bypassing I2P")%>"><input value="1" type="checkbox" name="DCC"<%=(editBean.getDCC(curTunnel) ? " checked=\"checked\"" : "")%> class="tickbox" />
                <%=intl._t("Enable Direct Client-to-Client protocol. Note that this will compromise your anonymity and is <i>not</i> recommended.")%></label>
            </td>
        </tr>

         <% } // ircclient %>
    </table>

    <h3><%=intl._t("Advanced networking options")%></h3>

    <table class="tunnelConfig">


<% if (!"streamrclient".equals(tunnelType)) { %> <% // no shared client tunnels for streamr %>
        <tr>
            <td class="infohelp" colspan="2">
                <%=intl._t("Note: When this client proxy is configured to share tunnels, then these options are for all the shared proxy clients!")%>
            </td>
        </tr>
         <% } // !streamrclient %>
        <tr>
            <th colspan="2">
                <%=intl._t("Tunnel Options")%>
            </th>
        </tr>
        <tr>
            <td>
                <b><%=intl._t("Length")%></b>
            </td>

            <td>
                <b><%=intl._t("Variance")%></b>
            </td>
        </tr>

        <tr>
            <td>
                <select id="tunnelDepth" name="tunnelDepth" title="<%=intl._t("Length of each Tunnel")%>" class="selectbox">
                    <% int tunnelDepth = editBean.getTunnelDepth(curTunnel, 3);
                  %><option value="0"<%=(tunnelDepth == 0 ? " selected=\"selected\"" : "") %>><%=intl._t("0 hop tunnel (no anonymity)")%></option>
                    <option value="1"<%=(tunnelDepth == 1 ? " selected=\"selected\"" : "") %>><%=intl._t("1 hop tunnel (low anonymity)")%></option>
                    <option value="2"<%=(tunnelDepth == 2 ? " selected=\"selected\"" : "") %>><%=intl._t("2 hop tunnel (medium anonymity)")%></option>
                    <option value="3"<%=(tunnelDepth == 3 ? " selected=\"selected\"" : "") %>><%=intl._t("3 hop tunnel (high anonymity)")%></option>
                <% if (editBean.isAdvanced()) {
                  %><option value="4"<%=(tunnelDepth == 4 ? " selected=\"selected\"" : "") %>>4 hop tunnel</option>
                    <option value="5"<%=(tunnelDepth == 5 ? " selected=\"selected\"" : "") %>>5 hop tunnel</option>
                    <option value="6"<%=(tunnelDepth == 6 ? " selected=\"selected\"" : "") %>>6 hop tunnel</option>
                    <option value="7"<%=(tunnelDepth == 7 ? " selected=\"selected\"" : "") %>>7 hop tunnel</option>
                <% } else if (tunnelDepth > 3) { 
                %>    <option value="<%=tunnelDepth%>" selected="selected"><%=tunnelDepth%> <%=intl._t("hop tunnel (very poor performance)")%></option>
                <% }
              %></select>
            </td>

            <td>
                <select id="tunnelVariance" name="tunnelVariance" title="<%=intl._t("Level of Randomization for Tunnel Length")%>" class="selectbox">
                    <% int tunnelVariance = editBean.getTunnelVariance(curTunnel, 0);
                  %><option value="0"<%=(tunnelVariance  ==  0 ? " selected=\"selected\"" : "") %>><%=intl._t("0 hop variance (no randomization, consistent performance)")%></option>
                    <option value="1"<%=(tunnelVariance  ==  1 ? " selected=\"selected\"" : "") %>><%=intl._t("+ 0-1 hop variance (medium additive randomization, subtractive performance)")%></option>
                    <option value="2"<%=(tunnelVariance  ==  2 ? " selected=\"selected\"" : "") %>><%=intl._t("+ 0-2 hop variance (high additive randomization, subtractive performance)")%></option>
                    <option value="-1"<%=(tunnelVariance == -1 ? " selected=\"selected\"" : "") %>><%=intl._t("+/- 0-1 hop variance (standard randomization, standard performance)")%></option>
                    <option value="-2"<%=(tunnelVariance == -2 ? " selected=\"selected\"" : "") %>><%=intl._t("+/- 0-2 hop variance (not recommended)")%></option>
                <% if (tunnelVariance > 2 || tunnelVariance < -2) {
                %>    <option value="<%=tunnelVariance%>" selected="selected"><%= (tunnelVariance > 2 ? "+ " : "+/- ") %>0-<%=tunnelVariance%> <%=intl._t("hop variance")%></option>
                <% }
              %></select>
            </td>
        </tr>
        <tr>
            <td>
                <b><%=intl._t("Count")%></b>
            </td>

            <td>
                <b><%=intl._t("Backup Count")%></b>
            </td>
        </tr>

        <tr>
            <td>
                <select id="tunnelQuantity" name="tunnelQuantity" title="<%=intl._t("Number of Tunnels in Group")%>" class="selectbox">
                    <%=editBean.getQuantityOptions(curTunnel, 0)%>
                </select>
            </td>

            <td>
                <select id="tunnelBackupQuantity" name="tunnelBackupQuantity" title="<%=intl._t("Number of Reserve Tunnels")%>" class="selectbox">
                    <% int tunnelBackupQuantity = editBean.getTunnelBackupQuantity(curTunnel, 0);
                  %><option value="0"<%=(tunnelBackupQuantity == 0 ? " selected=\"selected\"" : "") %>><%=intl._t("0 backup tunnels (0 redundancy, no added resource usage)")%></option>
                    <option value="1"<%=(tunnelBackupQuantity == 1 ? " selected=\"selected\"" : "") %>><%=intl._t("1 backup tunnel each direction (low redundancy, low resource usage)")%></option>
                    <option value="2"<%=(tunnelBackupQuantity == 2 ? " selected=\"selected\"" : "") %>><%=intl._t("2 backup tunnels each direction (medium redundancy, medium resource usage)")%></option>
                    <option value="3"<%=(tunnelBackupQuantity == 3 ? " selected=\"selected\"" : "") %>><%=intl._t("3 backup tunnels each direction (high redundancy, high resource usage)")%></option>
                <% if (tunnelBackupQuantity > 3) {
                %>    <option value="<%=tunnelBackupQuantity%>" selected="selected"><%=tunnelBackupQuantity%> <%=intl._t("backup tunnels")%></option>
                <% }
              %></select>
            </td>
        </tr>


         <% if (!"streamrclient".equals(tunnelType)) { %>
        <tr>
            <th>
                <%=intl._t("Profile")%>
            </th>

            <th>
                <%=intl._t("Delay Connect")%>
            </th>

        </tr>

        <tr>
            <td>
                <select id="connectionProfile" name="profile" title="<%=intl._t("Connection Profile")%>" class="selectbox">
                    <% boolean interactiveProfile = editBean.isInteractive(curTunnel);
                  %><option <%=(interactiveProfile == true  ? "selected=\"selected\" " : "")%>value="interactive"><%=intl._t("interactive connection")%> </option>
                    <option <%=(interactiveProfile == false ? "selected=\"selected\" " : "")%>value="bulk"><%=intl._t("bulk connection (downloads/websites/BT)")%> </option>
                </select>
            </td>

            <td>
                <label title="<%=intl._t("Delay Connection")%>"><input value="1000" type="checkbox" name="connectDelay"<%=(editBean.shouldDelay(curTunnel) ? " checked=\"checked\"" : "")%> class="tickbox" />
                (<%=intl._t("for request/response connections")%>)</label> <% // TODO: Convey to users: Where is the (1s) delay introduced? What is the difference between delay connect and delay open? %>
            </td>
        </tr>
         <% } // !streamrclient %>

        <tr>
            <th colspan="2">
                <%=intl._t("Router I2CP Address")%>
            </th>
        </tr>

        <tr>
            <td>
                <b><%=intl._t("Host")%>:</b>
                <input type="text" name="clientHost" size="20" title="<%=intl._t("I2CP Hostname or IP")%>" value="<%=editBean.getI2CPHost(curTunnel)%>" class="freetext host" <% if (editBean.isRouterContext()) { %> readonly="readonly" <% } %> />
            </td>


            <td>
                <b><%=intl._t("Port")%>:</b>
                <input type="text" name="clientport" size="20" title="<%=intl._t("I2CP Port Number")%>" value="<%=editBean.getI2CPPort(curTunnel)%>" class="freetext port" <% if (editBean.isRouterContext()) { %> readonly="readonly" <% } %> />
            </td>
        </tr>

         <% if (!"streamrclient".equals(tunnelType)) { // streamr client sends pings so it will never be idle %>

        <tr>
            <th colspan="2">
                <%=intl._t("Delay tunnel open until required")%>
            </th>
        </tr>

        <tr>
            <td colspan="2">
                <label title="<%=intl._t("Conserve resources by only creating tunnels when required")%>"><input value="1" type="checkbox" name="delayOpen"<%=(editBean.getDelayOpen(curTunnel) ? " checked=\"checked\"" : "")%> class="tickbox" />
                <%=intl._t("Delay opening client tunnel until activity is detected on the configured tunnel port")%></label>
            </td>
        </tr>

         <% } // !streamrclient %>

        <tr>
            <th colspan="2">
                <%=intl._t("Reduce tunnel quantity when idle")%>
            </th>
        </tr>

        <tr>
            <td colspan="2">
                <label title="<%=intl._t("Reduce tunnel count when idle but keep tunnel open (to ensure immediate availability)")%>"><input value="1" type="checkbox" name="reduce"<%=(editBean.getReduce(curTunnel) ? " checked=\"checked\"" : "")%> class="tickbox" />
                <%=intl._t("Reduce tunnel quantity when idle to conserve resources")%></label>
            </td>
        </tr>

        <tr>
            <td>
                <b><%=intl._t("Reduced tunnel count")%>:</b>
                <input type="text" id="reducedTunnelCount" name="reduceCount" size="1" maxlength="1" title="<%=intl._t("Reduced tunnel count")%>" value="<%=editBean.getReduceCount(curTunnel)%>" class="freetext quantity" />
            </td>

            <td>
                <b><%=intl._t("Idle period")%>:</b>
                <input type="text" name="reduceTime" size="4" maxlength="4" title="<%=intl._t("Reduced Tunnel Idle Time")%>" value="<%=editBean.getReduceTime(curTunnel)%>" class="freetext period" />
                minutes
            </td>
        </tr>

        <tr>
            <th colspan="2">
                <%=intl._t("Close tunnels when idle")%>
            </th>
        </tr>

        <tr>
            <td>
                <label title="<%=intl._t("To conserve resources, close tunnels when not in use")%>"><input value="1" type="checkbox" name="close"<%=(editBean.getClose(curTunnel) ? " checked=\"checked\"" : "")%> class="tickbox" />
                <%=intl._t("Close client tunnels after specified idle period")%></label>
            </td>

            <td>
                <b><%=intl._t("Idle period")%>:</b>
                <input type="text" name="closeTime" size="4" maxlength="4" title="<%=intl._t("Close Tunnel Idle Time")%>" value="<%=editBean.getCloseTime(curTunnel)%>" class="freetext period" />
                minutes
            </td>
        </tr>

        <tr>
            <td colspan="2">
                <b><%=intl._t("New Keys on Reopen")%>:</b>
                <span class="multiOption">
                    <label title="<%=intl._t("Change tunnel identity (destination) when tunnels reopen")%>"><input value="1" type="radio" name="newDest"
                        <%=(editBean.getNewDest(curTunnel) ? " checked=\"checked\"" : "")%> class="tickbox" />
                    <%=intl._t("Enable")%></label>
                </span>
                <span class="multiOption">
                    <label title="<%=intl._t("Retain tunnel identity (destination) when tunnels reopen")%>"><input value="0" type="radio" name="newDest"
                        <%=(editBean.getNewDest(curTunnel) || editBean.getPersistentClientKey(curTunnel) ? "" : " checked=\"checked\"")%> class="tickbox" />
                    <%=intl._t("Disable")%></label>
                </span>
            </td>
        </tr>

         <% if ("client".equals(tunnelType) || "ircclient".equals(tunnelType) || "socksirctunnel".equals(tunnelType) || "sockstunnel".equals(tunnelType)) { %>

        <tr>
            <th colspan="2">
                <%=intl._t("Persistent private key")%>
            </th>
        </tr>
        <tr>
            <td>
                <label title="<%=intl._t("Enabling this feature will ensure your tunnel identity (destination) remains static, for services offering features based on destination e.g. IRC user authentication")%>"><input value="2" type="radio" name="newDest"
                     <%=(editBean.getPersistentClientKey(curTunnel) ? " checked=\"checked\"" : "")%> class="tickbox" />
                <%=intl._t("Generate key to enable persistent client tunnel identity")%></label>
            </td>
            <td>
                <b><%=intl._t("File")%>:</b>
                <input type="text" size="30" id="privKeyFile" name="privKeyFile" title="<%=intl._t("Path to Private Key File")%>" value="<%=editBean.getPrivateKeyFile(curTunnel)%>" class="freetext" />
            </td>
        </tr>
         <%
            String destb64 = editBean.getDestinationBase64(curTunnel);
            if (destb64.length() > 0) {
           %>

        <tr>
            <td colspan="2">
                <b><%=intl._t("Local destination")%></b>
            </td>
        </tr>

        <tr>
            <td colspan="2">
                <div class="displayText" title="<%=intl._t("Read Only: Local Destination (if known)")%>" tabindex="0" onblur="resetScrollLeft(this)"><%=destb64%></div>
            </td>
        </tr>

        <tr>
            <td colspan="2">
                <b><%=intl._t("Local Base 32")%>:</b>&nbsp;
                <%=editBean.getDestHashBase32(curTunnel)%>
            </td>
        </tr>

         <% } // if destb64  %>
         <% } %>

         <% if ("httpclient".equals(tunnelType)) { %>

        <tr>
            <th colspan="2">
                <%=intl._t("HTTP Filtering")%>
            </th>
        </tr>

        <tr>
            <td>
                <label title="<%=intl._t("When enabled, the user agent of your web browser or http client will not be spoofed, potentially reducing your anonymity")%>"><input value="1" type="checkbox" name="allowUserAgent"<%=(editBean.getAllowUserAgent(curTunnel) ? " checked=\"checked\"" : "")%> class="tickbox" />
                <%=intl._t("Do not spoof User-Agent header")%></label>
            </td>
            <td>
                <label title="<%=intl._t("When enabled, the referer (originating page) of your web requests will not be filtered, potentially reducing your anonymity")%>"><input value="1" type="checkbox" name="allowReferer"<%=(editBean.getAllowReferer(curTunnel) ? " checked=\"checked\"" : "")%> class="tickbox" />
                <%=intl._t("Do not block Referer header")%></label>
            </td>
        </tr>

        <tr>
            <td>
                <label title="<%=intl._t("When enabled, the accept headers (mime types support) broadcast by your web browser will not be filtered, potentially reducing your anonymity")%>"><input value="1" type="checkbox" name="allowAccept"<%=(editBean.getAllowAccept(curTunnel) ? " checked=\"checked\"" : "")%> class="tickbox" />
<%=intl._t("Do not block Accept headers")%></label>
            </td>

            <td>
                <label title="<%=intl._t("Allow SSL to I2P addresses when enabled")%>"><input value="1" type="checkbox" name="allowInternalSSL"<%=(editBean.getAllowInternalSSL(curTunnel) ? " checked=\"checked\"" : "")%> class="tickbox" />
                <%=intl._t("Allow SSL to I2P addresses")%></label>
            </td>
        </tr>
         <% } // if httpclient %>

         <% if (true /* editBean.isAdvanced() */ ) {
                int currentSigType = editBean.getSigType(curTunnel, tunnelType);
           %>
        <tr>
            <th colspan="2">
                <%=intl._t("Signature type")%> (<%=intl._t("Experts only!")%>)
            </th>
        </tr>

        <tr>
            <td colspan="2">
                <span class="multiOption">
                    <label title="<%=intl._t("Legacy option (deprecated), provided for backward compatibility")%>"><input value="0" type="radio" name="sigType"<%=(currentSigType==0 ? " checked=\"checked\"" : "")%> class="tickbox" />
                    DSA-SHA1</label>
                </span>

           <% if (editBean.isSigTypeAvailable(1)) { %>

                <span class="multiOption">
                    <label><input value="1" type="radio" name="sigType"<%=(currentSigType==1 ? " checked=\"checked\"" : "")%> class="tickbox" />
                    ECDSA-P256</label>
                </span>

           <% }

              if (editBean.isSigTypeAvailable(2)) { %>

                <span class="multiOption">
                    <label><input value="2" type="radio" name="sigType"<%=(currentSigType==2 ? " checked=\"checked\"" : "")%> class="tickbox" />
                    ECDSA-P384</label>
                </span>

           <% }
              if (editBean.isSigTypeAvailable(3)) { %>

                <span class="multiOption">
                    <label><input value="3" type="radio" name="sigType"<%=(currentSigType==3 ? " checked=\"checked\"" : "")%> class="tickbox" />
                    ECDSA-P521</label>
                </span>

           <% }
              if (editBean.isSigTypeAvailable(7)) { %>

                <span class="multiOption">
                    <label title="<%=intl._t("This is the default, recommended option")%>"><input value="7" type="radio" name="sigType"<%=(currentSigType==7 ? " checked=\"checked\"" : "")%> class="tickbox" />
                    Ed25519-SHA-512</label>
                </span>
            </td>
        </tr>
           <% }   // isAvailable %>

         <% } // isAdvanced %>

         <% if ("httpclient".equals(tunnelType) || "connectclient".equals(tunnelType) || "sockstunnel".equals(tunnelType) || "socksirctunnel".equals(tunnelType)) { %>
        <tr>
            <th colspan="2">
                <%=intl._t("Local Authorization")%>
            </th>
        </tr>
        <tr>
            <td colspan="2">
                <label title="<%=intl._t("Enable to require a username and password to access this local service (for example if hosting on a LAN)")%>"><input value="1" type="checkbox" name="proxyAuth"<%=(editBean.getProxyAuth(curTunnel) ? " checked=\"checked\"" : "")%> class="tickbox" />
                <%=intl._t("Require local authorization for this service")%></label>
            </td>
        </tr>

        <tr>
            <td>
                <b><%=intl._t("Username")%>:</b>
                <input type="text" name="proxyUsername" title="<%=intl._t("Set username required to access this service")%>" value="" class="freetext username" />
            </td>
            <td>
                <b><%=intl._t("Password")%>:</b>
                <input type="password" name="nofilter_proxyPassword" title="<%=intl._t("Set password required to access this service")%>" value="" class="freetext password" />
            </td>
        </tr>

        <tr>
            <th colspan="2">
                <%=intl._t("Outproxy Authorization")%>
            </th>
        </tr>
        <tr>
            <td colspan="2">
                <label title="<%=intl._t("Enable if the outproxy a username and password to access")%>"><input value="1" type="checkbox" id="startOnLoad" name="outproxyAuth"<%=(editBean.getOutproxyAuth(curTunnel) ? " checked=\"checked\"" : "")%> class="tickbox" />
                <%=intl._t("Outproxy requires authorization")%></label>
            </td>
        </tr>

        <tr>
            <td>
                <b><%=intl._t("Username")%>:</b>
                <input type="text" name="outproxyUsername" title="<%=intl._t("Enter username required by outproxy")%>" value="<%=editBean.getOutproxyUsername(curTunnel)%>" class="freetext username" />
            </td>

            <td>
                <b><%=intl._t("Password")%>:</b>
                <input type="password" name="nofilter_outproxyPassword" title="<%=intl._t("Enter password required by outproxy")%>" value="<%=editBean.getOutproxyPassword(curTunnel)%>" class="freetext password" />
            </td>
        </tr>

         <% } // httpclient || connect || socks || socksirc %>

         <% if ("httpclient".equals(tunnelType)) { %>

        <tr>
            <th colspan="2">
                <%=intl._t("Jump URL List")%>
            </th>
        </tr>
        <tr>
            <td colspan="2">
                <textarea rows="2" style="height: 8em;" cols="60" id="hostField" name="jumpList" title="<%=intl._t("List of helper URLs to offer jumplinks from the web proxy error page when a host is not found in your addressbook")%>" wrap="off" spellcheck="false"><%=editBean.getJumpList(curTunnel)%></textarea>
            </td>
        </tr>

         <% } // httpclient %>

        <tr>
            <th colspan="2">
                <%=intl._t("Custom options")%>
            </th>
        </tr>

        <tr>
            <td colspan="2">
                <input type="text" id="customOptions" name="nofilter_customOptions" size="60" title="<%=intl._t("Advanced options to control tunnel priority etc")%>" value="<%=editBean.getCustomOptions(curTunnel)%>" class="freetext" spellcheck="false"/>
            </td>
        </tr>

        <tr>
            <td class="buttons" colspan="2">
                    <input type="hidden" value="true" name="removeConfirm" />
                    <button id="controlCancel" class="control" type="submit" name="action" value=""><%=intl._t("Cancel")%></button>
                    <button id="controlDelete" <%=(editBean.allowJS() ? "onclick=\"if (!confirm('Are you sure you want to delete?')) { return false; }\" " : "")%>class="control" type="submit" name="action" value="Delete this proxy" title="<%=intl._t("Delete this Proxy (cannot be undone)")%>"><%=intl._t("Delete")%></button>
                    <button id="controlSave" class="control" type="submit" name="action" value="Save changes"><%=intl._t("Save")%></button>
            </td>
        </tr>
    </table>
</div>
</form>

<%

  } else {
     %><div id="notReady"><%=intl._t("Tunnels not initialized yet; please retry in a few moments.")%></div><%
  }  // isInitialized()

%>
    </body>
</html>
