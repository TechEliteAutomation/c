// /home/u/c/frontend/src/App.jsx

import { useState, useEffect, useRef } from 'react';

// Icons remain the same...
const PlusIcon = () => <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-5 h-5"><path d="M10.75 4.75a.75.75 0 0 0-1.5 0v4.5h-4.5a.75.75 0 0 0 0 1.5h4.5v4.5a.75.75 0 0 0 1.5 0v-4.5h4.5a.75.75 0 0 0 0-1.5h-4.5v-4.5Z" /></svg>;
const SendIcon = () => <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-5 h-5"><path d="M3.105 2.289a.75.75 0 0 0-.826.95l1.414 4.949a.75.75 0 0 0 .95.574l3.906-1.116a.75.75 0 0 1 0 1.392l-3.906 1.116a.75.75 0 0 0-.95.574l-1.414 4.949a.75.75 0 0 0 .826.95l14.25-4.071a.75.75 0 0 0 0-1.392L3.105 2.289Z" /></svg>;
const FileIcon = () => <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-5 h-5"><path fillRule="evenodd" d="M4 2a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8.343a1 1 0 0 0-.293-.707l-3.43-3.43A1 1 0 0 0 13.657 4H4Zm6 6a.75.75 0 0 1 .75.75v.008l.008.002.002.002.002.002.002.002a.75.75 0 0 1 0 1.496l-.002.002-.002.002-.002.002-.008.002A.75.75 0 0 1 10 10.75Z" clipRule="evenodd" /></svg>;
const ChatIcon = () => <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-5 h-5"><path fillRule="evenodd" d="M2 5a3 3 0 0 1 3-3h10a3 3 0 0 1 3 3v5a3 3 0 0 1-3 3h-2.561l-3.872 3.443a.75.75 0 0 1-1.136-.664V13H5a3 3 0 0 1-3-3V5Zm1.5 0a1.5 1.5 0 0 1 1.5-1.5h10a1.5 1.5 0 0 1 1.5 1.5v5a1.5 1.5 0 0 1-1.5 1.5H12v1.336a.75.75 0 0 1-.375.65A.75.75 0 0 1 11 13.25V11.5h-1.5a.75.75 0 0 1 0-1.5H11V5.75a.75.75 0 0 1 1.5 0V10h1.5V5a1.5 1.5 0 0 1-1.5-1.5H5A1.5 1.5 0 0 1 3.5 5Z" clipRule="evenodd" /></svg>;

function App() {
  const [conversations, setConversations] = useState([]);
  const [currentConvo, setCurrentConvo] = useState(null);
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const [workspaceFiles, setWorkspaceFiles] = useState([]);
  const [activeFile, setActiveFile] = useState(null);
  const [fileContent, setFileContent] = useState("");
  // --- NEW: State for model selection ---
  const [selectedModel, setSelectedModel] = useState('gemini-1.5-pro-latest');
  const chatEndRef = useRef(null);

  useEffect(() => {
    fetchConversations();
    fetchWorkspaceFiles();
  }, []);

  useEffect(() => {
    chatEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const fetchConversations = () => {
    fetch('http://127.0.0.1:5001/api/conversations')
      .then(res => res.json())
      .then(data => setConversations(data));
  };

  const fetchWorkspaceFiles = () => {
    fetch('http://127.0.0.1:5001/api/workspace/files')
      .then(res => res.json())
      .then(data => setWorkspaceFiles(data));
  };

  const handleNewConversation = () => {
    fetch('http://127.0.0.1:5001/api/conversations', { method: 'POST' })
      .then(res => res.json())
      .then(newConvo => {
        setConversations([newConvo, ...conversations]);
        selectConversation(newConvo.id);
      });
  };

  const selectConversation = (id) => {
    setCurrentConvo(id);
    setActiveFile(null);
    setMessages([]);
    fetch(`http://127.0.0.1:5001/api/conversations/${id}/messages`)
      .then(res => res.json())
      .then(data => setMessages(data));
  };

  const selectFile = (filename) => {
    setActiveFile(filename);
    setFileContent(`Content of ${filename} would be displayed here.`);
  };

  const handleSendMessage = (e) => {
    e.preventDefault();
    if (!input.trim() || !currentConvo) return;

    const userMessage = { role: 'user', content: input };
    setMessages(prev => [...prev, userMessage]);

    fetch(`http://127.0.0.1:5001/api/conversations/${currentConvo}/messages`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      // --- NEW: Send the selected model with the request ---
      body: JSON.stringify({ content: input, model: selectedModel }),
    })
    .then(res => res.json())
    .then(aiMessage => {
      setMessages(prev => [...prev, aiMessage]);
      fetchConversations();
      if (input.toLowerCase().includes("create a file")) {
        setTimeout(fetchWorkspaceFiles, 500);
      }
    });

    setInput('');
  };

  return (
    <div className="flex h-screen bg-[#020617] text-gray-300 font-sans">
      {/* Sidebar */}
      <div className="w-1/4 bg-black/30 p-4 flex flex-col border-r border-blue-900/50">
        <h1 className="text-xl font-bold mb-4 text-white tracking-wider">AXIOM</h1>
        <button
          onClick={handleNewConversation}
          className="w-full flex items-center justify-center gap-2 bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded-lg mb-4 transition-all duration-300 focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          <PlusIcon /> New Nexus
        </button>
        
        <h2 className="text-xs font-bold uppercase text-blue-400/60 mt-4 mb-2 tracking-widest">Threads</h2>
        <div className="overflow-y-auto pr-2">
          {conversations.map(convo => (
            <div key={convo.id} onClick={() => selectConversation(convo.id)} className={`flex items-center gap-3 p-2 my-1 rounded-lg cursor-pointer truncate transition-all duration-200 ${currentConvo === convo.id ? 'bg-blue-800/50 text-white' : 'hover:bg-gray-800/50'}`}>
              <ChatIcon /> {convo.title}
            </div>
          ))}
        </div>

        <h2 className="text-xs font-bold uppercase text-blue-400/60 mt-6 mb-2 tracking-widest">Artifacts</h2>
        <div className="flex-grow overflow-y-auto pr-2">
          {workspaceFiles.map(file => (
            <div key={file} onClick={() => selectFile(file)} className={`flex items-center gap-3 p-2 my-1 rounded-lg cursor-pointer truncate transition-all duration-200 ${activeFile === file ? 'bg-blue-800/50 text-white' : 'hover:bg-gray-800/50'}`}>
              <FileIcon /> {file}
            </div>
          ))}
        </div>
      </div>

      {/* Main View */}
      <div className="flex-1 flex flex-col bg-black/20">
        {activeFile ? (
          <div className="flex-1 p-6 overflow-auto">
            <h2 className="text-lg font-bold mb-4 text-white">{activeFile}</h2>
            <pre className="bg-[#0f172a] p-4 rounded-lg text-sm overflow-auto">
              <code>{fileContent}</code>
            </pre>
          </div>
        ) : (
          <>
            <main className="flex-1 overflow-y-auto p-6">
              {messages.length === 0 && (
                <div className="text-center text-gray-500 mt-20">
                  <h2 className="text-2xl font-bold">AXIOM</h2>
                  <p>Select a Thread or start a new Nexus to begin.</p>
                </div>
              )}
              <div className="space-y-6">
                {messages.map((msg, index) => (
                  <div key={index} className={`flex items-start gap-4 ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}>
                    <div className={`max-w-2xl p-4 rounded-lg shadow-md ${msg.role === 'user' ? 'bg-blue-700 text-white' : 'bg-[#1e293b]'}`}>
                      <p className="whitespace-pre-wrap">{msg.content}</p>
                    </div>
                  </div>
                ))}
                <div ref={chatEndRef} />
              </div>
            </main>

            <div className="p-6 border-t border-blue-900/50">
              <form onSubmit={handleSendMessage} className="flex items-center">
                {/* --- NEW: Model Selector Dropdown --- */}
                <select 
                  value={selectedModel}
                  onChange={e => setSelectedModel(e.target.value)}
                  className="mr-4 p-3 bg-[#0f172a] border border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-600"
                >
                  <option value="gemini-1.5-pro-latest">Gemini 1.5 Pro</option>
                  <option value="llama3">Ollama (Llama3)</option>
                  {/* Add other ollama models here */}
                </select>

                <input
                  type="text"
                  value={input}
                  onChange={e => setInput(e.target.value)}
                  placeholder={currentConvo ? "Engage with Axiom..." : "Select a Thread"}
                  className="w-full p-3 bg-[#0f172a] border border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-600"
                  disabled={!currentConvo}
                />
                <button type="submit" className="ml-4 bg-blue-600 hover:bg-blue-700 text-white font-bold p-3 rounded-lg transition-colors disabled:opacity-50 flex items-center" disabled={!currentConvo || !input.trim()}>
                  <SendIcon />
                </button>
              </form>
            </div>
          </>
        )}
      </div>
    </div>
  );
}

export default App;
