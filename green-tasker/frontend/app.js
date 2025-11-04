// Prefer injected API URL (OpenShift), else same-origin (Flask serves frontend), else localhost
const API = window.API_URL || window.location.origin || 'http://127.0.0.1:5000';


async function fetchTasks(){
const r = await fetch(`${API}/tasks`);
return await r.json();
}


async function fetchAnalytics(){
const r = await fetch(`${API}/analytics`);
return await r.json();
}


function addRow(task){
const tbody = document.querySelector('#tasks-table tbody');
const tr = document.createElement('tr');
tr.innerHTML = `<td>${task.task_name}</td><td>${task.hours}</td><td>${task.energy_level}</td><td>${task.green_score}</td>`;
tbody.appendChild(tr);
}


async function refresh(){
const tasks = await fetchTasks();
document.querySelector('#tasks-table tbody').innerHTML = '';
tasks.forEach(addRow);
const an = await fetchAnalytics();
document.getElementById('green-score-badge').textContent = `Green Score: ${Math.round(an.avg_green_score)}`;
renderChart(an.distribution);
renderTips(an);
}


async function postTask(payload){
await fetch(`${API}/tasks`, {
method: 'POST', headers: {'Content-Type':'application/json'},
body: JSON.stringify(payload)
});
}


// Form
document.getElementById('task-form').addEventListener('submit', async (e)=>{
e.preventDefault();
const task = document.getElementById('task_name').value;
const hours = parseFloat(document.getElementById('hours').value)||1;
const category = document.getElementById('category').value||'General';
const energy_level = document.getElementById('energy_level').value;
await postTask({task_name: task, hours, category, energy_level});
document.getElementById('task-form').reset();
await refresh();
});


// Chart
let chart = null;
function renderChart(dist){
const ctx = document.getElementById('distChart').getContext('2d');
const labels = Object.keys(dist);
const data = Object.values(dist);
if(chart) { 
    chart.data.labels = labels;
    chart.data.datasets[0].data = data; 
    chart.update(); 
    return; 
}
chart = new Chart(ctx, {
type: 'pie',
data: { labels, datasets: [{ label: 'Tasks', data, backgroundColor: ['#28a745', '#17a2b8', '#ffc107', '#dc3545', '#6c757d'] }] },
options: { responsive: true, maintainAspectRatio: true }
});
}

function renderTips(an){
const tipsDiv = document.getElementById('tips');
tipsDiv.innerHTML = '<h6>Tips:</h6><ul class="list-unstyled">' + 
    an.tips.map(tip => `<li class="mb-2"><span class="badge bg-success"></span> ${tip}</li>`).join('') + 
    '</ul>';
}

// Initialize on page load
refresh();