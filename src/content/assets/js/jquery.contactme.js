function submitToAPI(event) {
    event.preventDefault(); // Prevent the default form submission

    // Validate the input fields
    if (!/[A-Za-z]{2,}/.test($("#name-input").val())) {
        alert("Name cannot be less than two characters");
        return;
    }
    if (!/[A-Za-z]{2,}/.test($("#message-input").val())) {
        alert("Message cannot be less than two characters");
        return;
    }
    if ($("#email-input").val().trim() === "") {
        alert("Please enter your email address");
        return;
    }
    if (!/^([\w-\.]+@([\w-]+\.)+[\w-]{2,6})?$/.test($("#email-input").val())) {
        alert("Please enter a valid email address");
        return;
    }

    // Gather the form data
    var name = $("#name-input").val();
    var email = $("#email-input").val();
    var message = $("#message-input").val();

    // Send the form data using AJAX
    $.ajax({
        type: "POST",
        url: "https://ebas0c03gb.execute-api.us-east-1.amazonaws.com/prod/contact",
        dataType: "json",
        crossDomain: true,
        contentType: "application/json; charset=utf-8",
        data: JSON.stringify({ name: name, email: email, message: message }),
        success: function () {
            alert("Thank you for your email! We will get back to you shortly.");
            document.getElementById("contact-form").reset();
            location.reload();
        },
        error: function () {
            alert("Unsuccessful");
        },
    });
}

// Add event listener for form submission
document.addEventListener('DOMContentLoaded', function () {
    document.getElementById('contact-form').addEventListener('submit', function(event) {
        submitToAPI(event);
    });
});