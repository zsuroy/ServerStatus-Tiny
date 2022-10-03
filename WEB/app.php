<?php
/*
* @note ServerStatusApi | running
* @author Suroy (https://suroy.cn)
* @date 22.10.2
*/

error_reporting(0);

define("FILE_NAME", "./json/stats.json");
define("PSK", "123"); //PASSWORD

$mod = isset($_GET['mod']) ? addslashes($_GET['mod']) : null;
$t = isset($_GET['t']) ? addslashes($_GET['t']) : null;
$code = isset($_GET['psk']) ? addslashes($_GET['psk']) : 2022;


// 处理校验码
codeCheck($code, $t); //校验

switch ($mod) {
    case null: //首页
        $mark = '访问成功';
        break;
    case 'get': // get
        if(is_file(FILE_NAME))
            $info = file_get_contents(FILE_NAME);
        else
            $info = '{"code":"-2","msg":"File not exist"}';
        //$info = base64_decode($info);
        exit($info);
        break;
    case 'update': //app设置信息
        $host = addslashes($_GET['host']);
        $param = addslashes($_POST['param']);
        if(strlen($param)<10){
            $param = addslashes(file_get_contents("php://input"));
        }
        //矫正json数据
        $param = str_replace("\\", "", trim($param));
        $param = str_replace(':,', ':0,', trim($param));
        $param = str_replace(':}', ':0}', trim($param));
        $param = str_replace(':.', ':', trim($param));
        $param = str_replace('days', 'd ', trim($param));
        $param = str_replace('weeks', 'w ', trim($param));
        $param = json_decode($param, true);
        if(!is_array($param))exit('{"code":"-2","msg":"data error"}');
        $param["uptime"] = is_numeric($param["uptime"]) ? date("H:i:s", $param["uptime"]):$param["uptime"];
        $param["updated"] = time();
        $param["ip"] = $_SERVER["REMOTE_ADDR"];
        $content = file_get_contents(FILE_NAME);
        $info = (array)json_decode($content, true);
        $existFlag = false;
        foreach($info["servers"] as $k => $v){
            if($v["host"] == $host){
                $info["servers"][$k] = $param;
                $existFlag = true;
                break;
            }
        }

        if(!$existFlag)$info["servers"][$k+1] = $param; // new
        $info["updated"] = time();

        file_put_contents(FILE_NAME, json_encode((array)$info, JSON_UNESCAPED_UNICODE), LOCK_EX);
        
        exit('{"code":"0","info":"Update Success ✅"}');
        break;
    default:
        exit('{"code":"-1","msg":"Access denied"}');
        break;
}


/**
 * 校验密码
 * $code 校验码
 * $t 时间戳
 */
function codeCheck($code, $t=null)
{
    $c = time() - intval($t);
    if($c >= -10 && $c < 30){
        // 生成密码
        if($code==PSK)
        return true;
    }
    exit('{"code":"-3","msg":"Code failure ❌"}');
}

/**
 * 直接重写配置文件
 * $content 写入内容
 */
function rewrite(){
    $content = file_get_contents('php://input');
    // $info = (array)json_decode($content, true);
    // var_dump($info);
    file_put_contents(FILE_NAME, $content);
}

