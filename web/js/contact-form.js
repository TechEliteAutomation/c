document.addEventListener("DOMContentLoaded", function() {
    let e = "sZpXVunUXQ9UdV7km",
        t = "service_c32q7a5",
        s = "template_rjaqoee";
    console.log("Attempting to initialize EmailJS with Public Key:", e), e && "YOUR_PUBLIC_KEY" !== e && !e.includes(" ") ? (emailjs.init(e), console.log("EmailJS Initialized successfully.")) : console.error("EmailJS Public Key ('" + e + "') is missing, a placeholder, or invalid (e.g., contains spaces). Form initialization failed.");
    let r = document.getElementById("contactForm"),
        n = document.getElementById("form-status"),
        o = r ? r.querySelector('button[type="submit"]') : null;
    if (r && o && n) {
        let a = o.textContent;
        r.addEventListener("submit", function(i) {
            if (i.preventDefault(), !t || "YOUR_EMAILJS_SERVICE_ID" === t || !s || "YOUR_EMAILJS_TEMPLATE_ID" === s || !e || "YOUR_PUBLIC_KEY" === e || "j-OrtrloWJVQ-6oHi" === e) {
                e && "YOUR_PUBLIC_KEY" !== e || console.error("EmailJS Public Key is missing or is the default placeholder."), t && "YOUR_EMAILJS_SERVICE_ID" !== t || console.error("EmailJS Service ID is missing or is the default placeholder."), s && "YOUR_EMAILJS_TEMPLATE_ID" !== s || console.error("EmailJS Template ID is missing or is the default placeholder."), n.textContent = "Form configuration error. Please contact the administrator.", n.className = "form-status-message form-status-error", o.disabled = !0, o.textContent = "Config Error";
                return
            }
            o.disabled = !0, o.textContent = "Sending...", n.textContent = "Sending your message...", n.className = "form-status-message form-status-sending", emailjs.sendForm(t, s, this).then(function() {
                n.textContent = "Message sent successfully! We'll be in touch soon.", n.className = "form-status-message form-status-success", o.textContent = "Sent!", r.reset();

                // --- THIS IS THE CRITICAL NEW CODE ---
                if (typeof gtag === 'function') {
                    gtag('event', 'contact_form_submit', {
                        'event_category': 'engagement',
                        'event_label': 'Contact Form Success'
                    });
                    console.log("GA4 event 'contact_form_submit' sent.");
                }
                // --- END OF NEW CODE ---

                setTimeout(() => {
                    o.disabled = !1, o.textContent = a, n.textContent = "", n.className = "form-status-message"
                }, 5e3)
            }, function(e) {
                console.error("EmailJS Send Error:", e);
                let t = "Failed to send message. Please try again or email us directly.";
                e && e.text ? t = `Failed to send message. Error (${e.status}): ${e.text}. Please try again or email us directly.` : e && (t = `Failed to send message. Error: ${JSON.stringify(e)}. Please try again or email us directly.`), n.textContent = t, n.className = "form-status-message form-status-error", o.textContent = "Send Failed", setTimeout(() => {
                    o.disabled = !1, o.textContent = a
                }, 5e3)
            })
        })
    } else r || console.error("Contact form with ID 'contactForm' not found."), o || console.error("Submit button within the contact form not found."), n || console.error("Form status element with ID 'form-status' not found.")
});
