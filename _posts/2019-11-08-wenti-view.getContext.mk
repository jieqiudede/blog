---
layout: post
title: 问题(View中的getContext一定返回的是Activity对象吗？)
---
> 不一定是，Activity中setContentView时一定是Activity;
通过 new View、View.inflate、LayoutInflater.inflate 这几种方式添加View，我们传参时传的是什么context, View中的就是什么Context. 当运行在5.0系统版本以下的手机，并且Activity是继承自AppCompatActivity的，那么View的getConext方法，返回的就不是Activity而是TintContextWrapper.  

