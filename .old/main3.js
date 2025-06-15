document.addEventListener("DOMContentLoaded",()=>{let e=document.querySelector(".menu-toggle"),t=document.querySelector(".nav-menu-container"),n=document.querySelectorAll(".nav-link");if(e&&t){let l=document.getElementById("nav-menu");e.addEventListener("click",()=>{let t="true"===e.getAttribute("aria-expanded");e.setAttribute("aria-expanded",!t),l.classList.toggle("nav-menu-opened")}),n.forEach(t=>{t.addEventListener("click",()=>{"none"!==getComputedStyle(e).display&&l.classList.contains("nav-menu-opened")&&(e.setAttribute("aria-expanded","false"),l.classList.remove("nav-menu-opened"))})})}let i=document.getElementById("current-year");i&&(i.textContent=new Date().getFullYear());let r=document.getElementById("theme-switcher"),a=document.documentElement,_=`
		<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="theme-icon" aria-hidden="true" focusable="false">
			<path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/>
		</svg>`,o=`
		<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" class="theme-icon" aria-hidden="true" focusable="false">
			<circle cx="12" cy="12" r="4" fill="currentColor"/>
			<line x1="12" y1="2" x2="12" y2="6"/>
			<line x1="12" y1="18" x2="12" y2="22"/>
			<line x1="4.93" y1="4.93" x2="7.76" y2="7.76"/>
			<line x1="16.24" y1="16.24" x2="19.07" y2="19.07"/>
			<line x1="2" y1="12" x2="6" y2="12"/>
			<line x1="18" y1="12" x2="22" y2="12"/>
			<line x1="4.93" y1="19.07" x2="7.76" y2="16.24"/>
			<line x1="16.24" y1="7.76" x2="19.07" y2="4.93"/>
		</svg>`;function s(e){a.setAttribute("data-theme",e),localStorage.setItem("theme",e),r&&("light"===e?(r.innerHTML=_,r.setAttribute("aria-label","Switch to dark mode")):(r.innerHTML=o,r.setAttribute("aria-label","Switch to light mode")))}function c(){let e=a.getAttribute("data-theme")||localStorage.getItem("theme")||"light";s("light"===e?"dark":"light")}function d(){let e=localStorage.getItem("theme"),t;s(t=e||"light")}r&&r.addEventListener("click",c),d()});
