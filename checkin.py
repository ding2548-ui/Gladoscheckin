import requests
import json
import os


def send_wechat(token, title, msg):
    """通过 PushPlus 推送消息到微信"""
    content = msg
    template = 'html'
    url = f"https://www.pushplus.plus/send?token={token}&title={title}&content={content}&template={template}"
    print(url)
    r = requests.get(url=url)
    print(r.text)


# ----------------------------------------------------------------------------------------------
# github workflows
# ----------------------------------------------------------------------------------------------
if __name__ == '__main__':
    # PushPlus token
    sckey = os.environ.get("SENDKEY", "")

    # 推送内容
    title = ""
    success, fail, repeats = 0, 0, 0        # 成功账号数量 失败账号数量 重复签到账号数量
    context = ""

    # glados账号cookie 多账号用 & 连接
    cookies_env = os.environ.get("COOKIES", "")
    cookies = cookies_env.split("&") if cookies_env else []

    if cookies and cookies[0] != "":

        check_in_url = "https://glados.cloud/api/user/checkin"        # 签到地址
        status_url = "https://glados.cloud/api/user/status"            # 查看账户状态

        referer = 'https://glados.cloud/console/checkin'
        origin = "https://glados.cloud"
        useragent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
        payload = {
            'token': 'glados.cloud'
        }

        for cookie in cookies:
            if not cookie.strip():
                continue

            try:
                checkin = requests.post(check_in_url, headers={
                    'cookie': cookie, 'referer': referer, 'origin': origin,
                    'user-agent': useragent, 'content-type': 'application/json;charset=UTF-8'
                }, data=json.dumps(payload), timeout=30)

                state = requests.get(status_url, headers={
                    'cookie': cookie, 'referer': referer, 'origin': origin,
                    'user-agent': useragent
                }, timeout=30)
            except requests.exceptions.RequestException as e:
                print(f"请求异常: {e}")
                fail += 1
                context += f"账号: 请求异常 | "
                continue

            message_status = ""
            points = 0
            message_days = ""
            email = ""

            if checkin.status_code == 200:
                # 解析返回的json数据
                result = checkin.json()
                # 获取签到结果
                check_result = result.get('message', '')
                points = result.get('points', 0)

                # 获取账号当前状态
                try:
                    state_result = state.json()
                    # 获取剩余时间
                    leftdays = int(float(state_result['data']['leftDays']))
                    # 获取账号email
                    email = state_result['data'].get('email', '')
                except (KeyError, ValueError, TypeError):
                    leftdays = 0

                print(check_result)
                if "Checkin! Got" in check_result:
                    success += 1
                    message_status = f"签到成功，会员点数 + {points}"
                elif "Checkin Repeats!" in check_result:
                    repeats += 1
                    message_status = "重复签到，明天再来"
                else:
                    fail += 1
                    message_status = f"签到失败: {check_result}"

                message_days = f"{leftdays} 天" if leftdays else "error"
            else:
                message_status = f"签到请求失败 (HTTP {checkin.status_code})"
                message_days = "error"
                fail += 1

            context += f"账号: {email}, P: {points}, 剩余: {message_days} | "

        # 推送内容
        if success > 0 and fail == 0:
            title = f"签到成功（{success}个账号）"
        elif fail > 0:
            title = f"签到异常：成功{success}，失败{fail}，重复{repeats}"
        else:
            title = message_status
        print("Send Content:\n", context)

    else:
        # 推送内容
        title = '# 未找到 cookies!'

    print("sckey:", sckey)
    print("cookies count:", len(cookies))

    # 推送消息
    if not sckey:
        print("Not push (SENDKEY not set)")
    else:
        send_wechat(sckey, title, context)
