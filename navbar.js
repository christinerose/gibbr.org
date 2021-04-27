
navbarItems = [
	{
		href: "index.html",
		name: "home"
	},
	{
		href: "software.html",
		name: "software"
	},
	{
		href: "projects/index.html",
		name: "projects"
	}
];

function setNavbarActiveTab() {
	// Gets depth of HTML page relative to project root
	const depth = 
		document.getElementsByTagName('script')[0].getAttribute('depth')
		|| 0;
	var pagepath = window.location.pathname;

	// Gets path of page relative to project root (with depth number of /'s)
	var index = pagepath.length;
	var i;
	for (i = 0; i <= depth; i++) {
		console.log(index)
		const new_index = pagepath.lastIndexOf('/', index - 1);
		if (new_index == -1) {
			break;
		}
		index = new_index;
	}
	if (index != -1) {
		pagepath = pagepath.substring(index + 1, pagepath.length)
	}
	// If the path is a directory, append with "index.html"
	if (pagepath[pagepath.length - 1] == "/") {
		pagepath += "index.html";
	}
	
	// Create navbar element
	const navbar = document.createElement('ul');
	navbar.classList.add("navbar");
	for (i = 0; i < navbarItems.length; i++) {
		link = document.createElement('a');
		link.href = "../".repeat(depth) + navbarItems[i].href;
		link.innerText = navbarItems[i].name;
		console.log(pagepath);
		if (navbarItems[i].href == pagepath) {
			link.classList.add("active");
		}
		listItem = document.createElement('li');
		listItem.appendChild(link);
		navbar.appendChild(listItem);
	}
	links = navbar.getElementsByTagName("a");
	for (i = 0; i < links.length; i++) {
	}
	document.body.prepend(navbar);
}

document.addEventListener("DOMContentLoaded", setNavbarActiveTab);
