
navbarItems = [
	{
		href: "index.html",
		name: "home"
	}
];

function setNavbarActiveTab() {
	const navbar = document.createElement('ul');
	navbar.classList.add("navbar");
	const pagepath = window.location.pathname;
	if (pagepath == "/") {
		const pagename = "index.html";
	} else {
		const pagename = pagepath.substring(pagepath.lastIndexOf('/') + 1);
	}
	for (i = 0; i < navbarItems.length; i++) {
		link = document.createElement('a');
		link.href = navbarItems[i].href;
		link.innerText = navbarItems[i].name;
		if (navbarItems[i].href == pagename) {
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
