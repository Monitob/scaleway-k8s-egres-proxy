package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"os"
	"strings"
	"time"
)

// SystemInfo holds information about the pod and node
type SystemInfo struct {
	PodName     string `json:"podName"`
	NodeName    string `json:"nodeName"`
	Namespace   string `json:"namespace"`
	HostIP      string `json:"hostIP"`
	PodIP       string `json:"podIP"`
	CurrentTime string `json:"currentTime"`
}

// ExternalIPResponse holds the response from external IP services
type ExternalIPResponse struct {
	IP          string `json:"ip"`
	CurrentTime string `json:"currentTime"`
}

// APIResponse holds responses from external APIs
type APIResponse struct {
	Origin      string `json:"origin"`
	Method      string `json:"method"`
	CurrentTime string `json:"currentTime"`
}

// Global variables for environment information
var (
	podName     = os.Getenv("POD_NAME")
	ifaceName   = os.Getenv("HOST_INTERFACE")
	namespace   = os.Getenv("POD_NAMESPACE")
	nodeName    = os.Getenv("NODE_NAME")
	proxyURL    = os.Getenv("PROXY_URL")
	proxyConfig = os.Getenv("PROXY_CONFIG")
)

func main() {
	// Set default values if environment variables are not set
	if podName == "" {
		podName = "unknown-pod"
	}
	if namespace == "" {
		namespace = "unknown-namespace"
	}
	if nodeName == "" {
		nodeName = "unknown-node"
	}
	if proxyURL == "" {
		proxyURL = "http://172.16.28.8:3128"
	}
	if proxyConfig == "" {
		proxyConfig = "HTTP_PROXY and HTTPS_PROXY environment variables"
	}

	// Print startup information
	fmt.Printf("Starting egress-multitenant-demo server\n")
	fmt.Printf("Pod: %s, Namespace: %s, Node: %s\n", podName, namespace, nodeName)
	fmt.Printf("Proxy configuration: %s\n", proxyConfig)
	fmt.Printf("Proxy URL: %s\n", proxyURL)

	// Set up HTTP routes
	http.HandleFunc("/", handleIndex)
	http.HandleFunc("/api/system", handleSystemInfo)
	http.HandleFunc("/api/external-ip", handleExternalIP)
	http.HandleFunc("/api/test-ipinfo", handleIPInfo)
	http.HandleFunc("/api/test-httpbin", handleHTTPBin)

	// Start the server
	port := "8080"
	if os.Getenv("PORT") != "" {
		port = os.Getenv("PORT")
	}

	fmt.Printf("Server listening on port %s\n", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}

func handleIndex(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/" {
		http.NotFound(w, r)
		return
	}

	// Read the index.html file
	content, err := os.ReadFile("static/index.html")
	if err != nil {
		// If file not found, serve a simple response
		http.Error(w, "Demo application is running", http.StatusOK)
		return
	}

	// Replace placeholders with actual values
	replaced := string(content)
	replaced = replacePlaceholder(replaced, "POD_NAME_PLACEHOLDER", podName)
	replaced = replacePlaceholder(replaced, "NODE_NAME_PLACEHOLDER", nodeName)
	replaced = replacePlaceholder(replaced, "NAMESPACE_PLACEHOLDER", namespace)
	replaced = replacePlaceholder(replaced, "PROXY_URL_PLACEHOLDER", proxyURL)

	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	fmt.Fprint(w, replaced)
}

func handleSystemInfo(w http.ResponseWriter, r *http.Request) {
	// Get host IP
	hostIP := getHostIP()

	// Get pod IP
	podIP := getPodIP()

	// Create response
	info := SystemInfo{
		PodName:     podName,
		NodeName:    nodeName,
		Namespace:   namespace,
		HostIP:      hostIP,
		PodIP:       podIP,
		CurrentTime: time.Now().Format(time.RFC3339),
	}

	// Send JSON response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(info)
}

func handleExternalIP(w http.ResponseWriter, r *http.Request) {
	// Create HTTP client that uses the proxy
	client := &http.Client{
		Timeout: 10 * time.Second,
		Transport: &http.Transport{
			Proxy: http.ProxyURL(os.Getenv("HTTP_PROXY")),
			DialContext: (&net.Dialer{
				Timeout:   5 * time.Second,
				KeepAlive: 30 * time.Second,
			}).DialContext,
			MaxIdleConns:          100,
			IdleConnTimeout:       90 * time.Second,
			TLSHandshakeTimeout:   10 * time.Second,
			ExpectContinueTimeout: 1 * time.Second,
		},
	}

	// Make request to get external IP
	resp, err := client.Get("https://api.ipify.org")
	if err != nil {
		http.Error(w, fmt.Sprintf("Error getting external IP: %v", err), http.StatusInternalServerError)
		return
	}
	defer resp.Body.Close()

	// Read response
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error reading response: %v", err), http.StatusInternalServerError)
		return
	}

	// Create response
	response := ExternalIPResponse{
		IP:          string(body),
		CurrentTime: time.Now().Format(time.RFC3339),
	}

	// Send JSON response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func handleIPInfo(w http.ResponseWriter, r *http.Request) {
	// Create HTTP client that uses the proxy
	client := &http.Client{
		Timeout: 10 * time.Second,
		Transport: &http.Transport{
			Proxy: http.ProxyURL(os.Getenv("HTTP_PROXY")),
			DialContext: (&net.Dialer{
				Timeout:   5 * time.Second,
				KeepAlive: 30 * time.Second,
			}).DialContext,
			MaxIdleConns:          100,
			IdleConnTimeout:       90 * time.Second,
			TLSHandshakeTimeout:   10 * time.Second,
			ExpectContinueTimeout: 1 * time.Second,
		},
	}

	// Make request to ipinfo.io
	resp, err := client.Get("https://ipinfo.io/json")
	if err != nil {
		http.Error(w, fmt.Sprintf("Error connecting to ipinfo.io: %v", err), http.StatusInternalServerError)
		return
	}
	defer resp.Body.Close()

	// Read response
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error reading response: %v", err), http.StatusInternalServerError)
		return
	}

	// Create response with additional timestamp
	var result map[string]interface{}
	if err := json.Unmarshal(body, &result); err != nil {
		http.Error(w, fmt.Sprintf("Error parsing response: %v", err), http.StatusInternalServerError)
		return
	}
	result["currentTime"] = time.Now().Format(time.RFC3339)

	// Send JSON response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(result)
}

func handleHTTPBin(w http.ResponseWriter, r *http.Request) {
	// Create HTTP client that uses the proxy
	client := &http.Client{
		Timeout: 10 * time.Second,
		Transport: &http.Transport{
			Proxy: http.ProxyURL(os.Getenv("HTTP_PROXY")),
			DialContext: (&net.Dialer{
				Timeout:   5 * time.Second,
				KeepAlive: 30 * time.Second,
			}).DialContext,
			MaxIdleConns:          100,
			IdleConnTimeout:       90 * time.Second,
			TLSHandshakeTimeout:   10 * time.Second,
			ExpectContinueTimeout: 1 * time.Second,
		},
	}

	// Make request to httpbin.org
	resp, err := client.Get("https://httpbin.org/json")
	if err != nil {
		http.Error(w, fmt.Sprintf("Error connecting to httpbin.org: %v", err), http.StatusInternalServerError)
		return
	}
	defer resp.Body.Close()

	// Read response
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error reading response: %v", err), http.StatusInternalServerError)
		return
	}

	// Create response with additional timestamp
	var result map[string]interface{}
	if err := json.Unmarshal(body, &result); err != nil {
		http.Error(w, fmt.Sprintf("Error parsing response: %v", err), http.StatusInternalServerError)
		return
	}
	result["currentTime"] = time.Now().Format(time.RFC3339)

	// Send JSON response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(result)
}

func getHostIP() string {
	// Try to get the host IP from the environment
	if ip := os.Getenv("HOST_IP"); ip != "" {
		return ip
	}

	// Try to get the host IP from the network interface
	if ifaceName != "" {
		iface, err := net.InterfaceByName(ifaceName)
		if err == nil {
			addrs, err := iface.Addrs()
			if err == nil {
				for _, addr := range addrs {
					if ipnet, ok := addr.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
						if ipnet.IP.To4() != nil {
							return ipnet.IP.String()
						}
					}
				}
			}
		}
	}

	// Fallback: use the default network interface
	conn, err := net.Dial("udp", "8.8.8.8:80")
	if err != nil {
		return "unknown"
	}
	defer conn.Close()

	localAddr := conn.LocalAddr().(*net.UDPAddr)
	return localAddr.IP.String()
}

func getPodIP() string {
	// Try to get the pod IP from the environment
	if ip := os.Getenv("POD_IP"); ip != "" {
		return ip
	}

	// Try to get the pod IP from the network interface
	addrs, err := net.InterfaceAddrs()
	if err != nil {
		return "unknown"
	}

	for _, addr := range addrs {
		if ipnet, ok := addr.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
			if ipnet.IP.To4() != nil {
				return ipnet.IP.String()
			}
		}
	}

	return "unknown"
}

func replacePlaceholder(content, placeholder, value string) string {
	return strings.ReplaceAll(content, placeholder, value)
}
