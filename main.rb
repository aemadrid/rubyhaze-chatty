$:.unshift "/Users/aemadrid/code/jars/"
require 'rubygems'
require 'rubyhaze'

RubyHaze.cluster

class Messages
  class << self

    def all
      @all ||= []
      puts "[Messages] @all [#{@all.inspect}]"
      @all
    end

    def add(user, text)
      puts "[Messages] add [#{user}] with [#{text}]"
      all << [user, text]
    end

    def formatted
      res = all.map {|user, text| "[#{user}] #{text}"}.join("\n")
      puts "[Messages] formatted [#{res}]"
      res
    end

  end
end

class Topic
  class << self
    def current
      @current ||= RubyHaze::Topic[:rubyhaze_chatty_topic]
    end

    def publish(user, text)
      puts "[topic] publishing [#{user}] with [#{text}]"
      current.publish "#{user}<|>#{text}"
    end
  end
end

class Users
  class << self
    attr_accessor :local

    def all
      @all ||= RubyHaze::Hash[:rubyhaze_chatty_users]
    end

    def add_local
      @host = java.net.InetAddress.local_host.host_name
      (1..100).each do |cnt|
        @local = "#{@host}_#{cnt}"
        if all[@local]
          puts "[Users] add_local : skipping [#{@local}]"
        else
          puts "[Users] add_local : adding [#{@local}]"
          all[@local] = Time.now.to_s
          Topic.publish @local, "has joined!"
          break
        end
      end
      puts "[users] #{all.map{|k,v| k}.join(" | ")}"
    end

    def formatted
      res = all.map {|login, time| "[#{login}] #{time}"}.join("\n")
      puts "[Users] formatted [#{res}]"
      res
    end

  end
end

Users.add_local

require 'java'
require 'swing-layout-1.0.3.jar'

import javax.swing.JFrame
import org.jdesktop.layout.GroupLayout
import org.jdesktop.layout.LayoutStyle

frame = JFrame.new "Chatty : connected as [#{Users.local}]"
frame.default_close_operation = JFrame::EXIT_ON_CLOSE
frame.minimum_size = java.awt.Dimension.new(550, 430)
frame.preferred_size = java.awt.Dimension.new(550, 430)

ta_messages = javax.swing.JTextArea.new 10, 5
sp_messages = javax.swing.JScrollPane.new
tf_message = javax.swing.JTextField.new
btn_send = javax.swing.JButton.new "Send"

font = java.awt.Font.new "Lucida Grande", 0, 12
ta_messages.font = font
tf_message.font = font
sp_messages.viewport_view = ta_messages

btn_send.add_action_listener do |evt|
  msg = tf_message.text.strip
  if msg.empty?
    puts "[btn_send] NOT adding [#{msg}], empty"
  else
    puts "[btn_send] adding [#{msg}]"
    Topic.publish Users.local, msg
  end
  tf_message.text = ''
end

Topic.current.on_message do |msg|
  user, msg = msg.split('<|>')
  puts "[topic] on_message [#{user}] with [#{msg}] on [#{ta_messages.inspect}]"
  Messages.add user, msg
  ta_messages.text = Messages.formatted
end

layout = GroupLayout.new frame.content_pane
frame.content_pane.layout = layout
layout.horizontal_group = layout.createParallelGroup(GroupLayout::LEADING).
  add(layout.createSequentialGroup.addContainerGap.
    add(layout.createParallelGroup(GroupLayout::LEADING).
    add(sp_messages, GroupLayout::DEFAULT_SIZE, 554, java.lang.Short::MAX_VALUE).
    add(GroupLayout::TRAILING,
      layout.createSequentialGroup.
         add(tf_message, GroupLayout::DEFAULT_SIZE, 468, java.lang.Short::MAX_VALUE).
         addPreferredGap(LayoutStyle::UNRELATED).
         add(btn_send))
    ).addContainerGap())
layout.vertical_group = layout.createParallelGroup(GroupLayout::LEADING).
  add(layout.createSequentialGroup().addContainerGap().
    add(sp_messages, GroupLayout::PREFERRED_SIZE, 342, GroupLayout::PREFERRED_SIZE).
    addPreferredGap(LayoutStyle::UNRELATED).
    add(layout.createParallelGroup(GroupLayout::BASELINE).
      add(tf_message, GroupLayout::PREFERRED_SIZE, GroupLayout::DEFAULT_SIZE, GroupLayout::PREFERRED_SIZE).
      add(btn_send)
    ).addContainerGap(GroupLayout::DEFAULT_SIZE, java.lang.Short::MAX_VALUE))

frame.pack
frame.visible = true