document.addEventListener("DOMContentLoaded", function() {
    document.getElementById("container").style.display = "none";
    document.getElementById("mainFrame").src = "";
});

window.addEventListener("message", function(e) {
    if (e.data.action === "open") {
        document.getElementById("mainFrame").src = e.data.url;
        document.getElementById("container").style.display = "flex";
    }

    if (e.data.action === "close") {
        document.getElementById("container").style.display = "none";
        document.getElementById("mainFrame").src = "";
    }
});

document.getElementById("closeBtn").addEventListener("click", function () {
    fetch(`https://${GetParentResourceName()}/close`, {
        method: "POST",
        body: JSON.stringify({})
    });
});
