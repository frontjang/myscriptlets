function Main()
{
	xsh.Screen.Synchronous = true;
	var lastDigit;
	lastDigit = xsh.Dialog.Prompt ("IP 마지막 자리?", "스크립트", "44", 0);

	telnet("0.0.0.0");
	telnet("0.0.0."+lastDigit);
}

function telnet(ip){
	xsh.Screen.Send("telnet "+ip);
	xsh.Screen.Send(String.fromCharCode(13));
	xsh.Session.Sleep(100);

	waitForNextString("ogin:");	
	xsh.Screen.Send("root");
	xsh.Screen.Send(String.fromCharCode(13));

	waitForNextString("assword:")
	xsh.Screen.Send("root");
	xsh.Screen.Send(String.fromCharCode(13));
}

function waitForNextString(str){
	do{
		var current=xsh.Screen.CurrentRow;
		var ReadLine = xsh.Screen.Get(current, 1, current, 40);
		if(ReadLine.indexOf(str)>0) {
			return;
		}
		xsh.Session.Sleep(10);
	}
	while(1);
}
