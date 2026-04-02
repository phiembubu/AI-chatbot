document.addEventListener('DOMContentLoaded', () => {

    /* --- Theme Toggling --- */
    const themeToggle = document.getElementById('theme-toggle');
    if (themeToggle) {
        const isDarkMode = localStorage.getItem('schoolhub_theme') === 'dark';
        if (isDarkMode) {
            document.body.classList.add('dark-mode');
            themeToggle.innerHTML = '<i class="fa-solid fa-sun"></i> Light Mode';
        }

        themeToggle.addEventListener('click', () => {
            document.body.classList.toggle('dark-mode');
            const isDark = document.body.classList.contains('dark-mode');

            localStorage.setItem('schoolhub_theme', isDark ? 'dark' : 'light');

            if (isDark) {
                themeToggle.innerHTML = '<i class="fa-solid fa-sun"></i> Light Mode';
            } else {
                themeToggle.innerHTML = '<i class="fa-solid fa-moon"></i> Dark Mode';
            }
        });
    }

    /* --- Chat Functionality --- */
    const chatInput = document.getElementById('chat-input');
    const sendBtn = document.getElementById('send-btn');
    const chatHistory = document.getElementById('chat-history');

    let sessionChatHistory = []; // Tracks role & content for backend RAG chaining

    if (chatInput && sendBtn && chatHistory) {

        chatInput.addEventListener('input', function () {
            this.style.height = 'auto';
            this.style.height = (this.scrollHeight) + 'px';
            if (this.value === '') {
                this.style.height = 'auto';
            }
        });

        sendBtn.addEventListener('click', handleSendMessage);

        chatInput.addEventListener('keydown', function (e) {
            if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault();
                handleSendMessage();
            }
        });

        async function handleSendMessage() {
            const message = chatInput.value.trim();
            if (!message) return;

            // 1. Append User Message
            appendUserMessage(message);

            // Clear input & reset size
            chatInput.value = '';
            chatInput.style.height = 'auto';

            // 2. Show Typing Indicator
            const typingIndicatorId = showTypingIndicator();

            try {
                // 3. API Call to Backend
                const response = await fetch('http://127.0.0.1:8000/ask', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        question: message,
                        chat_history: sessionChatHistory
                    })
                });

                removeTypingIndicator(typingIndicatorId);

                if (response.ok) {
                    const data = await response.json();
                    appendBotMessage(data.answer, message);

                    // Update frontend memory session 
                    sessionChatHistory.push({ role: "user", content: message });
                    sessionChatHistory.push({ role: "bot", content: data.answer });
                } else {
                    const err = await response.json();
                    appendBotMessage(`System Error: ${err.detail || 'The Backend was unable to process the query.'}`);
                }
            } catch (error) {
                removeTypingIndicator(typingIndicatorId);
                appendBotMessage(`Network Error: Ensure the API server is running at http://localhost:8000.`);
            }
        }

        function appendUserMessage(text) {
            const msgDiv = document.createElement('div');
            msgDiv.className = 'message user-message fade-in-up';
            msgDiv.innerHTML = `
                <div class="message-avatar"><i class="fa-regular fa-user"></i></div>
                <div class="message-content">
                    <div class="message-bubble">
                        <p>${escapeHTML(text)}</p>
                    </div>
                </div>
            `;
            chatHistory.appendChild(msgDiv);
            scrollToBottom();
        }

        function appendBotMessage(text, userQuestion = "") {
            const msgDiv = document.createElement('div');
            msgDiv.className = 'message bot-message fade-in-up';

            const feedbackHTML = `
                <div class="message-feedback">
                    <button class="feedback-btn upvote" title="Helpful"><i class="fa-regular fa-thumbs-up"></i></button>
                    <button class="feedback-btn downvote" title="Not helpful"><i class="fa-regular fa-thumbs-down"></i></button>
                    <button class="feedback-btn copy" title="Copy text"><i class="fa-regular fa-copy"></i></button>
                </div>
            `;

            msgDiv.innerHTML = `
                <div class="message-avatar"><i class="fa-solid fa-robot"></i></div>
                <div class="message-content">
                    <div class="message-bubble">
                        <p>${escapeHTML(text)}</p>
                    </div>
                    ${feedbackHTML}
                </div>
            `;

            chatHistory.appendChild(msgDiv);
            setupFeedbackButtons(msgDiv, text, userQuestion);
            scrollToBottom();
        }

        function showTypingIndicator() {
            const id = 'typing-' + Date.now();
            const msgDiv = document.createElement('div');
            msgDiv.className = 'message bot-message fade-in-up';
            msgDiv.id = id;
            msgDiv.innerHTML = `
                <div class="message-avatar"><i class="fa-solid fa-robot"></i></div>
                <div class="message-content">
                    <div class="message-bubble">
                        <div class="typing-indicator">
                            <span class="typing-dot"></span>
                            <span class="typing-dot"></span>
                            <span class="typing-dot"></span>
                        </div>
                    </div>
                </div>
            `;
            chatHistory.appendChild(msgDiv);
            scrollToBottom();
            return id;
        }

        function removeTypingIndicator(id) {
            const indicator = document.getElementById(id);
            if (indicator) indicator.remove();
        }

        function scrollToBottom() {
            chatHistory.scrollTop = chatHistory.scrollHeight;
        }

        function setupFeedbackButtons(messageElement, botAnswer, userQuestion) {
            const upBtn = messageElement.querySelector('.upvote');
            const downBtn = messageElement.querySelector('.downvote');
            const copyBtn = messageElement.querySelector('.copy');
            const textContent = messageElement.querySelector('.message-bubble p').innerText;

            const sendFeedback = async (rating) => {
                const username = typeof Auth !== 'undefined' && Auth.getSession() ? Auth.getSession().username : 'Anonymous';
                try {
                    await fetch('http://localhost:8000/feedback', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({
                            question: userQuestion,
                            answer: botAnswer,
                            rating: rating,
                            username: username
                        })
                    });
                } catch (e) {
                    console.error('Failed to submit feedback');
                }
            };

            upBtn.addEventListener('click', function () {
                if (!this.classList.contains('upvoted')) {
                    this.classList.add('upvoted');
                    downBtn.classList.remove('downvoted');
                    this.innerHTML = '<i class="fa-solid fa-thumbs-up"></i>';
                    downBtn.innerHTML = '<i class="fa-regular fa-thumbs-down"></i>';
                    sendFeedback('upvote');
                }
            });

            downBtn.addEventListener('click', function () {
                if (!this.classList.contains('downvoted')) {
                    this.classList.add('downvoted');
                    upBtn.classList.remove('upvoted');
                    this.innerHTML = '<i class="fa-solid fa-thumbs-down"></i>';
                    upBtn.innerHTML = '<i class="fa-regular fa-thumbs-up"></i>';
                    sendFeedback('downvote');
                }
            });

            copyBtn.addEventListener('click', function () {
                navigator.clipboard.writeText(textContent).then(() => {
                    this.innerHTML = '<i class="fa-solid fa-check"></i>';
                    setTimeout(() => {
                        this.innerHTML = '<i class="fa-regular fa-copy"></i>';
                    }, 2000);
                });
            });
        }
    }

    /* --- Admin Upload Functionality --- */
    const dropZone = document.getElementById('drop-zone');
    const fileInput = document.getElementById('file-input');
    const uploadBtn = document.getElementById('upload-btn');
    const docList = document.getElementById('doc-list');

    const progressContainer = document.getElementById('upload-progress-container');
    const progressFill = document.getElementById('progress-fill');
    const progressText = document.getElementById('progress-text');

    let selectedFiles = [];

    if (dropZone && fileInput && uploadBtn) {

        dropZone.addEventListener('click', () => fileInput.click());

        ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
            dropZone.addEventListener(eventName, preventDefaults, false);
        });

        function preventDefaults(e) {
            e.preventDefault();
            e.stopPropagation();
        }

        ['dragenter', 'dragover'].forEach(eventName => {
            dropZone.addEventListener(eventName, () => dropZone.classList.add('dragover'), false);
        });

        ['dragleave', 'drop'].forEach(eventName => {
            dropZone.addEventListener(eventName, () => dropZone.classList.remove('dragover'), false);
        });

        dropZone.addEventListener('drop', (e) => {
            handleFiles(e.dataTransfer.files);
        });

        fileInput.addEventListener('change', function () {
            handleFiles(this.files);
        });

        function handleFiles(files) {
            const txtFiles = Array.from(files).filter(f => f.name.endsWith('.txt'));
            if (txtFiles.length > 0) {
                selectedFiles = [...selectedFiles, ...txtFiles];
                updateUploadUI();
            } else {
                alert('Please upload .txt files only.');
            }
        }

        function updateUploadUI() {
            if (selectedFiles.length > 0) {
                uploadBtn.disabled = false;
                const fileNames = selectedFiles.map(f => f.name).join(', ');
                dropZone.querySelector('.drop-zone-text').innerText = `${selectedFiles.length} file(s) ready: ${fileNames}`;
            } else {
                uploadBtn.disabled = true;
                dropZone.querySelector('.drop-zone-text').innerText = `Drag & Drop files here or click to select`;
            }
        }

        // Live Upload Process
        uploadBtn.addEventListener('click', async () => {
            if (selectedFiles.length === 0) return;

            uploadBtn.disabled = true;
            progressContainer.classList.remove('hidden');
            progressFill.style.width = '30%';
            progressText.innerText = 'Uploading to Server & Vectorizing...';

            let uploadedCount = 0;

            for (const file of selectedFiles) {
                const formData = new FormData();
                formData.append('file', file);

                try {
                    const response = await fetch('http://localhost:8000/upload', {
                        method: 'POST',
                        body: formData
                    });

                    if (response.ok) {
                        appendToFileList(file.name);
                        uploadedCount++;
                    } else {
                        const err = await response.json();
                        alert(`Failed to upload ${file.name}: ${err.detail}`);
                    }
                } catch (e) {
                    alert(`Network error during upload. Ensure backend is running.`);
                    break;
                }
            }

            if (uploadedCount > 0) {
                progressFill.style.width = '100%';
                progressText.innerText = 'Knowledge Base Synced Successfully!';
            } else {
                progressContainer.classList.add('hidden');
            }

            setTimeout(() => {
                selectedFiles = [];
                updateUploadUI();
                progressContainer.classList.add('hidden');
                progressFill.style.width = '0%';
            }, 2500);
        });

        function appendToFileList(filename) {
            const emptyState = docList.querySelector('.empty-state');
            if (emptyState) emptyState.remove();

            const li = document.createElement('li');
            const timestamp = new Date().toLocaleTimeString();
            li.innerHTML = `
                <i class="fa-solid fa-file-lines"></i>
                <div style="flex-grow: 1;">
                    <strong>${filename}</strong>
                    <br>
                    <small style="color: var(--text-tertiary);">Ingested at ${timestamp}</small>
                </div>
                <i class="fa-solid fa-circle-check" style="color: var(--secondary);"></i>
            `;
            docList.prepend(li);
        }
    }

    function escapeHTML(str) {
        return str.replace(/[&<>'"]/g,
            tag => ({
                '&': '&amp;',
                '<': '&lt;',
                '>': '&gt;',
                "'": '&#39;',
                '"': '&quot;'
            }[tag] || tag)
        );
    }
});
