// ==UserScript==
// @name         Clear & Bookmark Watch Later
// @namespace    http://tampermonkey.net/
// @version      3.0
// @description  Removes videos from YouTube Watch Later and provides a downloadable bookmark file of the removed videos.
// @author       You
// @match        *://www.youtube.com/playlist?list=WL*
// @grant        none
// @run-at       document-end
// ==/UserScript==

(function() {
    'use strict';

    let removalInProgress = false;
    let bookmarksToSave = []; // Array to store {title, url} objects

    // --- UI Control Panel ---
    const addControlPanel = () => {
        const controlPanel = document.createElement('div');
        controlPanel.style.position = 'fixed';
        controlPanel.style.top = '80px';
        controlPanel.style.right = '20px';
        controlPanel.style.zIndex = '10000';
        controlPanel.style.padding = '15px';
        controlPanel.style.backgroundColor = 'rgba(20, 20, 20, 0.95)';
        controlPanel.style.border = '1px solid #444';
        controlPanel.style.borderRadius = '8px';
        controlPanel.style.color = 'white';
        controlPanel.style.fontFamily = 'Roboto, Arial, sans-serif';

        const title = document.createElement('h3');
        title.textContent = 'Watch Later Control';
        title.style.margin = '0 0 10px 0';
        title.style.fontSize = '16px';

        const startButton = document.createElement('button');
        startButton.textContent = 'Start Clearing';
        startButton.id = 'start-clear-wl';
        startButton.style.padding = '8px 12px';
        startButton.style.cursor = 'pointer';
        startButton.style.border = '1px solid #555';
        startButton.style.backgroundColor = '#333';
        startButton.style.color = 'white';
        startButton.style.borderRadius = '4px';
        startButton.onclick = toggleRemoval;

        const stopButton = document.createElement('button');
        stopButton.textContent = 'Stop';
        stopButton.style.padding = '8px 12px';
        stopButton.style.cursor = 'pointer';
        stopButton.style.marginLeft = '5px';
        stopButton.style.border = '1px solid #555';
        stopButton.style.backgroundColor = '#500';
        stopButton.style.color = 'white';
        stopButton.style.borderRadius = '4px';
        stopButton.onclick = toggleRemoval;

        const saveButton = document.createElement('button');
        saveButton.textContent = 'Save Bookmarks';
        saveButton.id = 'save-bookmarks-wl';
        saveButton.style.padding = '8px 12px';
        saveButton.style.cursor = 'pointer';
        saveButton.style.marginTop = '10px';
        saveButton.style.border = '1px solid #1a73e8';
        saveButton.style.backgroundColor = '#1a73e8';
        saveButton.style.color = 'white';
        saveButton.style.borderRadius = '4px';
        saveButton.style.width = '100%';
        saveButton.disabled = true;
        saveButton.onclick = downloadBookmarkFile;

        const statusDiv = document.createElement('div');
        statusDiv.id = 'wl-clear-status';
        statusDiv.style.marginTop = '12px';
        statusDiv.style.fontSize = '14px';
        statusDiv.textContent = 'Ready';

        controlPanel.appendChild(title);
        controlPanel.appendChild(startButton);
        controlPanel.appendChild(stopButton);
        controlPanel.appendChild(saveButton);
        controlPanel.appendChild(statusDiv);
        document.body.appendChild(controlPanel);
    };

    const setStatus = (message) => {
        const statusEl = document.getElementById('wl-clear-status');
        if (statusEl) statusEl.textContent = message;
    };

    const finishProcess = (message) => {
        setStatus(message);
        document.getElementById('start-clear-wl').disabled = false;
        if (bookmarksToSave.length > 0) {
            document.getElementById('save-bookmarks-wl').disabled = false;
        }
        removalInProgress = false;
    };

    // --- Core Removal & Saving Logic ---
    const removeNextVideo = async () => {
        if (!removalInProgress) {
            finishProcess('Process stopped by user.');
            return;
        }

        const firstVideo = document.querySelector('ytd-playlist-video-renderer');

        if (!firstVideo) {
            finishProcess(`Complete! ${bookmarksToSave.length} videos removed.`);
            console.log('Watch Later playlist cleared.');
            return;
        }

        // --- Step 1: Extract video info BEFORE deleting ---
        const linkElement = firstVideo.querySelector('a#video-title');
        if (linkElement) {
            const title = linkElement.getAttribute('title');
            const url = 'https://www.youtube.com' + linkElement.getAttribute('href');
            bookmarksToSave.push({ title, url });
            setStatus(`Saved: ${title.substring(0, 30)}...`);
        } else {
            console.warn("Could not find video title/link for a video. It will be skipped.");
        }

        // --- Step 2: Remove the video ---
        const menuButton = firstVideo.querySelector('yt-icon-button.ytd-menu-renderer');
        if (!menuButton) {
            finishProcess('Error: Could not find menu button.');
            return;
        }

        menuButton.click();
        await new Promise(resolve => setTimeout(resolve, 500));

        const menuItems = document.querySelectorAll('ytd-menu-service-item-renderer');
        const removeButton = Array.from(menuItems).find(item => {
            const text = item.textContent || item.innerText;
            return text.trim().toLowerCase().startsWith('remove from');
        });

        if (removeButton) {
            removeButton.click();
            setStatus(`Removed video #${bookmarksToSave.length}`);
            await new Promise(resolve => setTimeout(resolve, 1500));
            removeNextVideo(); // Process the next video
        } else {
            document.body.click(); // Close menu
            finishProcess('Error: Could not find "Remove" button.');
        }
    };

    const toggleRemoval = () => {
        const startButton = document.getElementById('start-clear-wl');
        if (removalInProgress) {
            removalInProgress = false;
            startButton.disabled = false;
            setStatus('Stopping...');
        } else {
            removalInProgress = true;
            startButton.disabled = true;
            document.getElementById('save-bookmarks-wl').disabled = true;
            setStatus('Starting...');
            removeNextVideo();
        }
    };

    // --- Bookmark File Generation ---
    const downloadBookmarkFile = () => {
        if (bookmarksToSave.length === 0) {
            setStatus("No bookmarks to save.");
            return;
        }

        let bookmarkFileContent = `<!DOCTYPE NETSCAPE-Bookmark-file-1>
<!--This is an automatically generated file.
It will be read and overwritten.
Do Not Edit! -->
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
<TITLE>Bookmarks</TITLE>
<H1>Bookmarks</H1>
<DL><p>
    <DT><H3 ADD_DATE="${Math.floor(Date.now() / 1000)}" LAST_MODIFIED="${Math.floor(Date.now() / 1000)}">YouTube Watch Later Backup</H3>
    <DL><p>\n`;

        bookmarksToSave.forEach(bookmark => {
            // Sanitize title to prevent breaking the HTML structure
            const safeTitle = bookmark.title.replace(/&/g, '&').replace(/</g, '<').replace(/>/g, '>');
            bookmarkFileContent += `        <DT><A HREF="${bookmark.url}" ADD_DATE="${Math.floor(Date.now() / 1000)}">${safeTitle}</A>\n`;
        });

        bookmarkFileContent += `    </DL><p>\n</DL><p>\n`;

        const blob = new Blob([bookmarkFileContent], { type: 'text/html' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = 'youtube-watch-later-backup.html';
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
        setStatus("Bookmark file downloaded!");
    };

    // --- Initialization ---
    const observer = new MutationObserver((mutations, obs) => {
        if (document.querySelector('ytd-playlist-video-renderer')) {
            addControlPanel();
            obs.disconnect();
        }
    });

    observer.observe(document.body, { childList: true, subtree: true });

})();
