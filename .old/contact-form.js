// Wait for the HTML document to be fully loaded and parsed
document.addEventListener('DOMContentLoaded', function () {

    // --- START: EmailJS Configuration ---
    // IMPORTANT: Ensure these values exactly match your EmailJS dashboard!
    // - Public Key: Account -> API Keys
    // - Service ID: Email Services -> (Your service)
    // - Template ID: Email Templates -> (Your template)
    const EMAILJS_PUBLIC_KEY = 'sZpXVunUXQ9UdV7km';     // Your Public Key
    const EMAILJS_SERVICE_ID = 'service_c32q7a5';    // Your Service ID
    const EMAILJS_TEMPLATE_ID = 'template_rjaqoee';   // Your Template ID
    // --- END: EmailJS Configuration ---

    // --- Initialize EmailJS ---
    // Check if the Public Key looks valid (exists and is not a known placeholder)
    // Add a console log to verify the key being used:
    console.log("Attempting to initialize EmailJS with Public Key:", EMAILJS_PUBLIC_KEY);

    if (EMAILJS_PUBLIC_KEY && EMAILJS_PUBLIC_KEY !== 'YOUR_PUBLIC_KEY' && !EMAILJS_PUBLIC_KEY.includes(' ')) { // Check if it's defined, not the placeholder 'YOUR_PUBLIC_KEY', and has no spaces
         emailjs.init(EMAILJS_PUBLIC_KEY);
         console.log("EmailJS Initialized successfully."); // Add confirmation log
    } else {
        console.error("EmailJS Public Key ('" + EMAILJS_PUBLIC_KEY + "') is missing, a placeholder, or invalid (e.g., contains spaces). Form initialization failed.");
        // Optionally disable the form or show an error message permanently here
        // For now, the later checks will catch configuration errors too.
    }
    // --- End Initialization ---


    const contactForm = document.getElementById('contactForm');
    const formStatus = document.getElementById('form-status');
    const submitButton = contactForm ? contactForm.querySelector('button[type="submit"]') : null;

    if (contactForm && submitButton && formStatus) { // Ensure all elements exist
        const originalButtonText = submitButton.textContent;

        contactForm.addEventListener('submit', function(event) {
            event.preventDefault(); // Prevent default form submission

            // --- Preliminary Check ---
            // Check if Service ID or Template ID are missing or still placeholders
            // We re-check the public key here just in case init failed silently earlier
            if (!EMAILJS_SERVICE_ID || EMAILJS_SERVICE_ID === 'YOUR_EMAILJS_SERVICE_ID' ||
                !EMAILJS_TEMPLATE_ID || EMAILJS_TEMPLATE_ID === 'YOUR_EMAILJS_TEMPLATE_ID' ||
                !EMAILJS_PUBLIC_KEY || EMAILJS_PUBLIC_KEY === 'YOUR_PUBLIC_KEY' || EMAILJS_PUBLIC_KEY === 'j-OrtrloWJVQ-6oHi') { // Removed incorrect check from init, adding a basic check here

                // Check specifically which one is missing/placeholder for better debugging
                if (!EMAILJS_PUBLIC_KEY || EMAILJS_PUBLIC_KEY === 'YOUR_PUBLIC_KEY') {
                     console.error("EmailJS Public Key is missing or is the default placeholder.");
                }
                 if (!EMAILJS_SERVICE_ID || EMAILJS_SERVICE_ID === 'YOUR_EMAILJS_SERVICE_ID') {
                     console.error("EmailJS Service ID is missing or is the default placeholder.");
                 }
                 if (!EMAILJS_TEMPLATE_ID || EMAILJS_TEMPLATE_ID === 'YOUR_EMAILJS_TEMPLATE_ID') {
                     console.error("EmailJS Template ID is missing or is the default placeholder.");
                 }

                formStatus.textContent = 'Form configuration error. Please contact the administrator.';
                formStatus.className = 'form-status-message form-status-error'; // Use CSS class
                submitButton.disabled = true; // Keep button disabled
                submitButton.textContent = 'Config Error';
                return; // Stop the submission process
            }

            // --- Start Submission Process ---
            submitButton.disabled = true;
            submitButton.textContent = 'Sending...';
            formStatus.textContent = 'Sending your message...';
            formStatus.className = 'form-status-message form-status-sending'; // Use CSS class

            // Send the form data using EmailJS
            // 'this' refers to the form element itself
            // NOTE: sendForm implicitly uses the key from init(), but passing it again doesn't hurt
            // and might be necessary if init() had issues that weren't fatal errors.
            emailjs.sendForm(EMAILJS_SERVICE_ID, EMAILJS_TEMPLATE_ID, this /*, EMAILJS_PUBLIC_KEY */) // Public key is optional here if init() worked
                .then(function() {
                    // --- Success ---
                    formStatus.textContent = 'Message sent successfully! We\'ll be in touch soon.';
                    formStatus.className = 'form-status-message form-status-success'; // Use CSS class
                    submitButton.textContent = 'Sent!';
                    contactForm.reset(); // Clear the form fields

                    // Reset button and status message after a delay
                    setTimeout(() => {
                        submitButton.disabled = false;
                        submitButton.textContent = originalButtonText;
                        formStatus.textContent = '';
                        formStatus.className = 'form-status-message'; // Reset class
                    }, 5000); // 5 seconds

                }, function(error) {
                    // --- Error ---
                    console.error('EmailJS Send Error:', error);
                    // Display EmailJS specific error text if available
                    let errorMessage = 'Failed to send message. Please try again or email us directly.';
                    if (error && error.text) {
                         errorMessage = `Failed to send message. Error (${error.status}): ${error.text}. Please try again or email us directly.`;
                    } else if (error) {
                         errorMessage = `Failed to send message. Error: ${JSON.stringify(error)}. Please try again or email us directly.`;
                    }

                    formStatus.textContent = errorMessage;
                    formStatus.className = 'form-status-message form-status-error'; // Use CSS class
                    submitButton.textContent = 'Send Failed';

                    // Reset button after a delay
                     setTimeout(() => {
                        submitButton.disabled = false;
                        submitButton.textContent = originalButtonText;
                    }, 5000); // 5 seconds
                });
        });
    } else {
        // Log an error if essential elements are missing
        if (!contactForm) console.error("Contact form with ID 'contactForm' not found.");
        if (!submitButton) console.error("Submit button within the contact form not found.");
        if (!formStatus) console.error("Form status element with ID 'form-status' not found.");
    }

}); // End of DOMContentLoaded listener
