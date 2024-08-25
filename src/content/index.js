const counter = document.querySelector(".view-counter");

async function updateCounter() {
    try {
        let response = await fetch(
            "https://w7yxkz4b5a.execute-api.us-east-1.amazonaws.com/test/verify-json"
        );
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        let data = await response.json();
        
        if (data && data.visitorCount !== undefined) {
            counter.innerHTML = `Views: ${data.visitorCount}`;
        } else {
            counter.innerHTML = "Views: N/A";
        }
    } catch (error) {
        console.error("Failed to update the view counter:", error);
        counter.innerHTML = "Views: N/A";
    }
}

updateCounter();
