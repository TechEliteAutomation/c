// START OF FILE: js/main.js
document.addEventListener('DOMContentLoaded', () => {
    // --- Mobile Menu Toggle ---
    const menuToggle = document.querySelector('.menu-toggle');
    const navMenuContainer = document.querySelector('.nav-menu-container');
    const navLinks = document.querySelectorAll('.nav-link'); // Get all nav links

    if (menuToggle && navMenuContainer) {
        menuToggle.addEventListener('click', () => {
            const isExpanded = menuToggle.getAttribute('aria-expanded') === 'true' || false;
            menuToggle.setAttribute('aria-expanded', !isExpanded);
            navMenuContainer.classList.toggle('active'); // You'll need CSS for .nav-menu-container.active
            // Simple way to show/hide on mobile:
            if (navMenuContainer.classList.contains('active')) {
                navMenuContainer.style.display = 'block'; // Or 'flex' if it's a flex container
            } else {
                navMenuContainer.style.display = 'none'; // Hide it
            }
        });

        // Close menu when a nav link is clicked (optional, good for SPAs or single-page feel)
        navLinks.forEach(link => {
            link.addEventListener('click', () => {
                if (window.innerWidth < 768 && navMenuContainer.classList.contains('active')) { // Check if mobile view and menu is open
                    menuToggle.setAttribute('aria-expanded', 'false');
                    navMenuContainer.classList.remove('active');
                    navMenuContainer.style.display = 'none';
                }
            });
        });
    }
     // CSS for .nav-menu-container.active might be needed for mobile:
     // @media (max-width: 767px) {
     //   .nav-menu-container { display: none; flex-direction: column; ... }
     //   .nav-menu-container.active { display: flex; }
     // }
     // The current CSS hides .menu-toggle on desktop and shows .nav-menu-container.
     // The toggle logic above might need refinement based on exact mobile CSS.
     // For now, ensure `.nav-menu-container` is visible by default on desktop via CSS
     // and the JS toggle only affects it on mobile (e.g., by checking window.innerWidth).
     // The provided CSS handles this with @media queries making .menu-toggle display:none and .nav-menu-container display:flex above 768px.
     // The JS should primarily handle aria-expanded and a class for any transition/animation.
     // The current CSS relies on the .menu-toggle being display:none on desktop.
     // The JS for navMenuContainer.style.display might conflict with CSS. A class toggle is better.
     // Let's refine the mobile menu JS slightly to rely on a class:
     if (menuToggle && navMenuContainer) {
        // Re-selecting navMenuContainer as it's block-scoped in the previous if
        const mobileNavContainer = document.getElementById('nav-menu'); // Use ID for specificity

        menuToggle.addEventListener('click', () => {
            const isExpanded = menuToggle.getAttribute('aria-expanded') === 'true';
            menuToggle.setAttribute('aria-expanded', !isExpanded);
            mobileNavContainer.classList.toggle('nav-menu-opened'); // Add/remove this class
        });

        // Add CSS:
        // @media (max-width: 767px) {
        //   .nav-menu-container { /* Base styles for mobile hidden menu */
        //     display: none; /* or position absolute off-screen */
        //     /* other styles like width: 100%, background, etc. */
        //   }
        //   .nav-menu-container.nav-menu-opened {
        //     display: flex; /* Or block, depending on your layout */
        //     flex-direction: column;
        //   }
        //   .nav-links { flex-direction: column; width: 100%; }
        //   .nav-links li { width: 100%; }
        //   .nav-link { display: block; text-align: center; }
        //   .theme-toggle-button { margin: 0.5rem auto; } /* Center theme button in mobile menu */
        // }
        // The existing CSS for .nav-menu-container display:flex might be an issue for mobile.
        // The current style.css shows .nav-menu-container at 768px+ and hides .menu-toggle.
        // Below 768px, .menu-toggle is shown, .nav-menu-container default state needs to be "closed".
        // This part needs careful CSS and JS coordination. The provided CSS does not have explicit mobile menu open/close state.
        // For now, I will assume the user will add the required CSS for `.nav-menu-opened` on `.nav-menu-container` for mobile.
    }


    // --- Current Year in Footer ---
    const currentYearSpan = document.getElementById('current-year');
    if (currentYearSpan) {
        currentYearSpan.textContent = new Date().getFullYear();
    }

    // --- Theme Switcher Logic ---
    const themeSwitcher = document.getElementById('theme-switcher');
    const htmlElement = document.documentElement;
    const moonIcon = '🌙'; // Unicode moon icon
    const sunIcon = '☀️'; // Unicode sun icon

    function applyTheme(theme) {
        htmlElement.setAttribute('data-theme', theme);
        localStorage.setItem('theme', theme);
        if (themeSwitcher) {
            if (theme === 'light') {
                themeSwitcher.textContent = moonIcon;
                themeSwitcher.setAttribute('aria-label', 'Switch to dark mode');
            } else {
                themeSwitcher.textContent = sunIcon;
                themeSwitcher.setAttribute('aria-label', 'Switch to light mode');
            }
        }
        // Update logo src if using different files (more robust than CSS content for img tags)
        const logos = document.querySelectorAll('.navbar-logo, .footer-logo, .maintenance-logo'); // Add other logo classes/IDs if any
        logos.forEach(logo => {
            if (theme === 'light') {
                // Assuming you have a logo version for light backgrounds.
                // If techelite-logo.png has transparent parts and dark text + white text,
                // it might partially disappear on a light background.
                // A logo specifically for light backgrounds is recommended.
                // Example: logo.src = '/assets/images/techelite-logo-light-bg.png';
                // For now, we rely on the CSS var --logo-image-url and content property, or filters for SVGs.
                // If your .navbar-logo is an <img> tag, CSS `content: var(...)` won't work.
                // Let's ensure logos are updated via JS if they are <img> tags.
                // The current HTML uses <img> for logos.
                if (logo.tagName === 'IMG') {
                    // Check if a light mode specific logo exists, otherwise keep default or apply filter via CSS
                    // This example assumes you will create 'techelite-logo-for-light.png' if needed.
                    // If not, remove this or rely on CSS filters if those work for your PNG.
                    // logo.src = theme === 'light' ? '/assets/images/techelite-logo-for-light.png' : '/assets/images/techelite-logo.png';
                }
            }
        });
    }

    function toggleTheme() {
        const currentTheme = htmlElement.getAttribute('data-theme') || (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
        const newTheme = currentTheme === 'light' ? 'dark' : 'light';
        applyTheme(newTheme);
    }

    function initializeTheme() {
        const savedTheme = localStorage.getItem('theme');
        const systemPrefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
        let currentTheme;

        if (savedTheme) {
            currentTheme = savedTheme;
        } else if (systemPrefersDark) {
            currentTheme = 'dark';
        } else {
            currentTheme = 'light'; // Default to light if no saved theme and no system dark preference
        }
        applyTheme(currentTheme);
    }

    if (themeSwitcher) {
        themeSwitcher.addEventListener('click', toggleTheme);
    }

    initializeTheme(); // Set the theme on initial load
});
// END OF FILE: js/main.js