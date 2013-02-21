-------------------------------------------------------------------------------
-- Copyright (c) 2012 Sierra Wireless and others.
-- All rights reserved. This program and the accompanying materials
-- are made available under the terms of the Eclipse Public License v1.0
-- which accompanies this distribution, and is available at
-- http://www.eclipse.org/legal/epl-v10.html
--
-- Contributors:
--     Sierra Wireless - initial API and implementation
-------------------------------------------------------------------------------

require 'sched'
sched.listen(4648)
sched.run(function() require "tests.managers.TestDailyFwk" end) -- start the ReadyAgent
sched.loop() -- main loop: run the scheduler