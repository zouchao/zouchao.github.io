---
date: 2015-10-31 10:00:00
title: after_save和after_commit使用的误区
layout: post
tags:
    - elasticsearch
    - sidekiq
    - after_save
    - after_commit
    - ActiveRecord
categories:
    - ruby
    - rails
---

> Callbacks are methods that get called at certain moments of an object's life cycle. With callbacks it is possible to write code that will run whenever an Active Record object is created, saved, updated, deleted, validated, or loaded from the database.

以上是[RailsGuides][railsguides]对`ActiveRecord`的回调的解释，大致意思是：  
> **回调是在对象生命周期的特定时刻执行的方法。回调方法可以在 Active Record 对象创建、保存、更新、删除、验证或从数据库中读出时执行。**

我们有很多场景都会用到，但是某些情况你可能会发现其实他们也没有你想象中那么好用，比如说，你有一个问答网站，并希望所有的问题都能被搜索到，为了搜索的效率你又引入了`ElasticSearch`，es的数据需要索引，而为了构建索引的效率以及实时性，你又引入了sidekiq。听起来很复杂，其实这种比你想象中要常见的多。

而此时视乎是使用`after_save`的绝佳时机，因此，在你的模型中，你大概会这样写：

<div class="file_title">
  app/models/question.rb
</div>
<pre class="prettyprint linenums">
class Question < ActiveRecord::Base
  after_save :index_for_search

  # ...

  private

  def index_for_search
    QuestionIndexerJob.perform_later(self)
  end
end
</pre>
<div class="file_title">
app/jobs/question_indexer_job.rb
</div>
<pre class="prettyprint linenums">
class QuestionIndexerJob < ActiveJob::Base
  queue_as :default

  def perform(question)
    # ... index the question ...
  end
end
</pre>
到这看起来似乎都是完美的。直到你查看你的`sidekiq`日志，看到这些错误显示：

```log
2015-03-10T05:29:02.881Z 52530 TID-oupf889w4 WARN: Error while trying to deserialize arguments: Couldn't find Question with 'id'=3
```
当然`sidekiq`里面可以使用重试机制，让索引构建成功，但是发生这样的错误还是很怪异，对吧？

#### 多线程和多进程的错
其实此处的`sidekiq`相当于形成了一个多进程来执行查询，是的sidekiq是单独的进程在运行。而`after_save`执行回调时，事物并没有提交。此时在另一个进程中运行的`sidekiq`自然也就查询不到数据。

是的，我们自然而然的应该想到`ActiveRecord`的另外一个关于事物的回调`after_commit`，修改模型：
<div class="file_title">
  app/models/question.rb
</div>
<pre class="prettyprint linenums">
class Question < ActiveRecord::Base
  after_commit :index_for_search, on: [:create, :update]

  # ...
end
</pre>

再观察`sidekiq`日志，发现问题确实解决了。完美

### 高兴太早，还有一个问题

当你是用了一堆`after_commit`来替换`after_save`之后，接下来我们运行一下测试：

<div class="file_title">
  test/models/question_test.rb
</div>
<pre class="prettyprint linenums">
require 'test_helper'

class QuestionTest < ActiveSupport::TestCase
  test "A saved question is queued for indexing" do
    assert_enqueued_with(job: QuestionIndexerJob) do
      Question.create(title: "Is it legal to kill a zombie?")
    end
  end
end
</pre>

```shell
 1) Failure:
QuestionTest#test_A_saved_question_is_queued_for_indexing [/Users/jweiss/Source/testapps/after_commit/test/models/question_test.rb:7]:
No enqueued job found with {:job=>QuestionIndexerJob}
```
哎哟，什么情况？不是只换了一个回调方法嘛，而且作用都差不多。发生了什么？

默认情况下，rails的测试是每个测试用例使用 ** 一个事物 ** 包裹,这确实对测试效率提升很大。只需一个指令即可撤销在该测试用例中执行的所有数据库操作。因此你的数据在保存的时候并没有事物提交，so你的after_commit也根本不会执行。

其实这个问题也有一个比较简单的方式来解决，那就是引入一个叫`test_after_commit`的gem包：


<div class="file_title">
Gemfile
</div>
<pre class="prettyprint linenums">
group :test do
  gem "test_after_commit"
end
</pre>
这样有`after_commit`的回调就能在测试中再加一层事物, 得到我们想要的效果。但是也许你还是会觉得别扭，为毛我要为这事儿单独去加载一个gem？你是对的，这非常别扭。但是这事也不会持续太久了，因为`rails5`中已经修复了这个问题：[https://github.com/rails/rails/pull/18458][rails5]

<pre> 本文译自： <a href="http://www.justinweiss.com/articles/a-couple-callback-gotchas-and-a-rails-5-fix/" title="A Couple of Callback Gotchas (and a Rails 5 Fix)" >A Couple of Callback Gotchas (and a Rails 5 Fix) | Justin Weiss's blog</a></pre>



[rails5]: https://github.com/rails/rails/pull/18458
[railsguides]: http://guides.rubyonrails.org/active_record_callbacks.html
