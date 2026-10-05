package main

import (
	"log"
	"net/http"
	"os/exec"
)

func main() {
	http.Handle("/", http.FileServer(http.Dir("assets/")))

	http.HandleFunc("/wake", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
			return
		}

		cmd := exec.Command("wakeonlan", "XX:XX:XX:XX:XX:XX")
		if err := cmd.Run(); err != nil {
			log.Println(err)
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		log.Println("homelab awoken")
	})

	log.Println("listening on :8067")
	if err := http.ListenAndServe(":8067", nil); err != nil {
		log.Println(err)
	}
}
