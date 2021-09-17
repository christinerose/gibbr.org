
navbarItems = [
	{
		href: "/",
		name: "Home"
	},
	{
		href: "/software.html",
		name: "Software"
	},
	{
		href: "/projects/",
		name: "Projects"
	}
];

function setNavbarActiveTab() {
	var pagepath = window.location.pathname;

	if (pagepath.endsWith("index.html")) {
		pagepath = pagepath.substring( 0, pagepath.indexOf("index.html"))
	}
	
	// Create navbar element
	const navbar = document.createElement('ul');
	navbar.classList.add("navbar");
	navbar.id = "navbar";
	for (i = 0; i < navbarItems.length; i++) {
		link = document.createElement('a');
		link.href = navbarItems[i].href;
		link.innerText = navbarItems[i].name;
		console.log(pagepath);
		if (navbarItems[i].href == pagepath || navbarItems[i].href == pagepath + ".html") {
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
