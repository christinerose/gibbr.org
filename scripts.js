
navbarHMLT = '\
	<ul class="navbar">\
		<li><a href="index.html">home</a></li>\
	</ul>\
'

function setNavbarActiveTab() {
	const navbar = document.createElement('div');
	navbar.innerHTML = navbarHMLT;
	const pagepath = window.location.pathname;
	const pagename = pagepath.substring(pagepath.lastIndexOf('/') + 1);
	links = navbar.getElementsByTagName("a")
	for (i = 0; i < links.length; i++) {
		if (links[i].attributes.href.value == pagename) {
			links[i].classList.add("active")
		}
	}
	document.getElementById("navbar-div").innerHTML = navbar.innerHTML;
}

document.addEventListener("DOMContentLoaded", setNavbarActiveTab);
