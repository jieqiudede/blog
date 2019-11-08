---
layout: post
title: 问题(ANR)
---
# AppErrors.appNotResponding();
> 该方法是最终弹出ANR对话框的唯一入口，调用该方法的场景才会有ANR提示，也可以认为在主线程中执行无论再耗时的任务，只要最终不调用该方法，都不会有ANR提示，也不会有ANR相关日志及报告；通过调用关系可以看出哪些场景会导致ANR，有以下四种场景：  
* （1）Service Timeout:Service在特定的时间内无法处理完成；
* （2）BroadcastQueue Timeout：BroadcastReceiver在特定时间内无法处理完成
* （3）ContentProvider Timeout：内容提供者执行超时
* （4）inputDispatching Timeout: input事件分派(按键或触摸)事件在特定时间内无响应。  
> 在input事件分派超时的时候，有两种情况不会弹框，分别是：  
* (1)处于debug时；
* (2)来自子进程；(这个情况下会直接kill掉子进程)  

